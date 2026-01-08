import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../mixins/auth_token_mixin.dart';
import 'utils/phone_fixer_utils.dart';
import 'widgets/summary_card.dart';
import 'widgets/change_card.dart';
import 'dialogs/edit_pending_dialog.dart';

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
    setState(() => _isPushing = true);
    try {
      final idToken = await getIdToken(context);
      final result = await _api.pushToGoogle(idToken);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Pushed ${result['pushed']} contacts, ${result['skipped']} skipped',
            ),
            backgroundColor: const Color(0xFF10b981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isPushing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
    final changes = _filteredChanges;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search changes...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Pending Changes'),
        actions: [
          if (_data != null && (_data!['changes'] as List).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete All',
              onPressed: _clearAll,
            ),
          _buildSortMenu(),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
          ? const Center(child: CircularProgressIndicator())
          : changes.isEmpty && _searchQuery.isNotEmpty
          ? const Center(child: Text('No matches found'))
          : Column(
              children: [
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
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isPushing ? null : _pushToGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPushing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload),
                            const SizedBox(width: 8),
                            Text(
                              'Sync ${summary['accepts'] + summary['edits']} Changes',
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
