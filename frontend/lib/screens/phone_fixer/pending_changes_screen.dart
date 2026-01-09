import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/background_sync_service.dart';
import '../../providers/sync_state_provider.dart';
import '../../mixins/auth_token_mixin.dart';
import 'utils/phone_fixer_utils.dart';
import 'widgets/summary_card.dart';
import 'widgets/change_card.dart';
import 'dialogs/edit_pending_dialog.dart';
import 'dialogs/push_progress_dialog.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/sync_progress_banner.dart';

class PendingChangesScreen extends StatefulWidget {
  final String regionCode;

  const PendingChangesScreen({super.key, required this.regionCode});

  @override
  State<PendingChangesScreen> createState() => _PendingChangesScreenState();
}

class _PendingChangesScreenState extends State<PendingChangesScreen>
    with AuthTokenMixin {
  late final ApiService _api;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isPushing = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateAdded;
  bool _isAscending = false;

  List<Map<String, dynamic>> get _filteredChanges {
    final changes = List<Map<String, dynamic>>.from(_data?['changes'] ?? []);
    List<Map<String, dynamic>> result;

    if (_searchQuery.isEmpty) {
      result = changes;
    } else {
      final query = _searchQuery.toLowerCase();
      result = changes.where((c) {
        final name = (c['contact_name'] ?? '').toString().toLowerCase();
        final phone = (c['original_phone'] ?? '').toString().toLowerCase();
        final newPhone = (c['new_phone'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            newPhone.contains(query);
      }).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_sortOption) {
        case SortOption.name:
          cmp = (a['contact_name'] ?? '').toString().compareTo(
            b['contact_name'] ?? '',
          );
          break;
        case SortOption.phone:
          cmp = (a['original_phone'] ?? '').toString().compareTo(
            b['original_phone'] ?? '',
          );
          break;
        case SortOption.dateAdded:
          final dateA = a['created_at'] != null
              ? DateTime.tryParse(a['created_at'])
              : null;
          final dateB = b['created_at'] != null
              ? DateTime.tryParse(b['created_at'])
              : null;
          if (dateA == null && dateB == null) {
            cmp = 0;
          } else if (dateA == null) {
            cmp = 1;
          } else if (dateB == null) {
            cmp = -1;
          } else {
            cmp = dateA.compareTo(dateB);
          }
          break;
        case SortOption.lastModified:
          final updatedA = a['updated_at'] ?? a['created_at'];
          final updatedB = b['updated_at'] ?? b['created_at'];
          final dateMA = updatedA != null ? DateTime.tryParse(updatedA) : null;
          final dateMB = updatedB != null ? DateTime.tryParse(updatedB) : null;
          if (dateMA == null && dateMB == null) {
            cmp = 0;
          } else if (dateMA == null) {
            cmp = 1;
          } else if (dateMB == null) {
            cmp = -1;
          } else {
            cmp = dateMA.compareTo(dateMB);
          }
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    _api = createApiService(context);
    _loadPendingChanges();
  }

  Future<void> _loadPendingChanges() async {
    setState(() => _isLoading = true);
    try {
      final idToken = await getIdToken(context);
      final result = await _api.getPendingChanges(idToken);
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pushToGoogle() async {
    final summary = _data?['summary'] ?? {};
    final totalContacts = (summary['accepts'] ?? 0) + (summary['edits'] ?? 0);

    if (totalContacts == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to sync')));
      return;
    }

    final idToken = await getIdToken(context);
    if (idToken == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication required')));
      return;
    }

    final baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

    // On web or if background sync is already running, use in-app dialog
    if (kIsWeb || BackgroundSyncService().isRunning) {
      await showPushProgressDialog(
        context: context,
        baseUrl: baseUrl,
        idToken: idToken,
        totalContacts: totalContacts,
      );
      if (mounted) Navigator.pop(context);
      return;
    }

    // On native platforms, use background sync with notifications
    final syncService = BackgroundSyncService();
    final syncState = context.read<SyncStateProvider>();

    final started = await syncService.startSync(
      baseUrl: baseUrl,
      idToken: idToken,
      totalContacts: totalContacts,
      syncStateProvider: syncState,
      onComplete: (pushed, failed, skipped) {
        debugPrint(
          'Sync complete: $pushed pushed, $failed failed, $skipped skipped',
        );
        // Reload the list after completion
        if (mounted) _loadPendingChanges();
      },
    );

    if (started && mounted) {
      // Stay on screen to show progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing in background. Progress shown above.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _editPendingChange(Map<String, dynamic> change) {
    showEditPendingDialog(
      context: context,
      change: change,
      regionCode: widget.regionCode,
      onSave: (newName, newPhone) async {
        try {
          final idToken = await getIdToken(context);
          await _api.stageFix(
            idToken: idToken,
            resourceName: change['resource_name'],
            contactName: change['contact_name'],
            originalPhone: change['original_phone'],
            newPhone: newPhone,
            action: 'edit',
            newName: newName,
          );
          _loadPendingChanges();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error update: $e')));
          }
        }
      },
    );
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Changes?'),
        content: const Text(
          'This will remove all pending changes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final idToken = await getIdToken(context);
      if (!mounted) return;

      await _api.clearStaged(idToken);
      _loadPendingChanges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All pending changes deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _handleSortSelection(dynamic value) {
    if (value is SortOption) {
      if (_sortOption == value) {
        setState(() => _isAscending = !_isAscending);
      } else {
        setState(() {
          _sortOption = value;
          _isAscending = true;
        });
      }
    } else if (value is String) {
      setState(() {
        if (value == 'ASC') _isAscending = true;
        if (value == 'DESC') _isAscending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _data?['summary'] ?? {};

    // Watch sync state for reactive updates when contacts are synced
    final syncState = context.watch<SyncStateProvider>();
    final syncedNames = syncState.syncedContactNames;

    // Get filtered changes, excluding already-synced contacts
    final allChanges = _filteredChanges;
    final changes = allChanges.where((c) {
      final name = c['contact_name']?.toString() ?? '';
      return !syncedNames.contains(name);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search changes...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Text(
                'Pending Changes',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [
          if (_data != null && (_data!['changes'] as List).isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_forever_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Delete All',
              onPressed: _clearAll,
            ),
          _buildSortMenu(),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary,
              ),
            )
          : changes.isEmpty && _searchQuery.isNotEmpty
          ? Center(
              child: Text(
                'No matches found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          : Column(
              children: [
                // Show progress banner during background sync
                const SyncProgressBanner(),
                if (!_isSearching)
                  SummaryCard(
                    accepts: summary['accepts'] ?? 0,
                    rejects: summary['rejects'] ?? 0,
                    edits: summary['edits'] ?? 0,
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: changes.length,
                    itemBuilder: (context, index) {
                      final change = changes[index];
                      return ChangeCard(
                        change: change,
                        onEdit: () => _editPendingChange(change),
                        onDelete: () async {
                          final idToken = await getIdToken(context);
                          await _api.removeStagedChange(
                            idToken,
                            change['resource_name'],
                          );
                          _loadPendingChanges();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _data != null && (summary['total'] ?? 0) > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: NeumorphicButton(
                  onTap: _isPushing ? () {} : _pushToGoogle,
                  color: const Color(0xFF10b981), // Accent color for action
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _isPushing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sync ${summary['accepts'] + summary['edits']} Changes',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<dynamic>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort By',
      onSelected: _handleSortSelection,
      itemBuilder: (context) => [
        _buildSortMenuItem(SortOption.name, 'Name'),
        _buildSortMenuItem(SortOption.phone, 'Phone'),
        _buildSortMenuItem(SortOption.dateAdded, 'Date Added'),
        _buildSortMenuItem(SortOption.lastModified, 'Last Modified'),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          checked: _isAscending,
          value: 'ASC',
          child: const Text('Ascending'),
        ),
        CheckedPopupMenuItem(
          checked: !_isAscending,
          value: 'DESC',
          child: const Text('Descending'),
        ),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(
    SortOption option,
    String label,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Text(label),
          if (_sortOption == option)
            Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
    );
  }
}
