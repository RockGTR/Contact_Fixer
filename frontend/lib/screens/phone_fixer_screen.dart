import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../mixins/auth_token_mixin.dart';
import 'phone_fixer/pending_changes_screen.dart';
import 'phone_fixer/utils/phone_fixer_utils.dart';
import 'phone_fixer/widgets/control_toolbar.dart';
import 'phone_fixer/widgets/empty_state.dart';
import 'phone_fixer/dialogs/edit_contact_dialog.dart';
import 'phone_fixer/views/swipe_view_mode.dart';
import 'phone_fixer/views/list_view_mode.dart';

class PhoneFixerScreen extends StatefulWidget {
  final String regionCode;

  const PhoneFixerScreen({super.key, required this.regionCode});

  @override
  State<PhoneFixerScreen> createState() => _PhoneFixerScreenState();
}

class _PhoneFixerScreenState extends State<PhoneFixerScreen>
    with AuthTokenMixin {
  final CardSwiperController _controller = CardSwiperController();
  late final ApiService _api;

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  int _acceptCount = 0;
  int _rejectCount = 0;
  int _editCount = 0;
  bool _isSwipeView = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.name;
  bool _isAscending = true;

  Map<String, dynamic> _pendingStats = {};

  List<Map<String, dynamic>> get _filteredContacts {
    List<Map<String, dynamic>> result;
    if (_searchQuery.isEmpty) {
      result = List.from(_contacts);
    } else {
      final query = _searchQuery.toLowerCase();
      result = _contacts.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_sortOption) {
        case SortOption.name:
          cmp = (a['name'] ?? '').toString().compareTo(b['name'] ?? '');
          break;
        case SortOption.phone:
          cmp = (a['phone'] ?? '').toString().compareTo(b['phone'] ?? '');
          break;
        case SortOption.lastModified:
          final dateA = a['updated_at'] != null
              ? DateTime.tryParse(a['updated_at'])
              : null;
          final dateB = b['updated_at'] != null
              ? DateTime.tryParse(b['updated_at'])
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
        case SortOption.dateAdded:
          cmp = 0;
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
    _loadContacts();
    _loadPendingStats();
  }

  Future<void> _loadPendingStats() async {
    try {
      final idToken = await getIdToken(context);
      final result = await _api.getPendingChanges(idToken);
      if (mounted) {
        setState(() => _pendingStats = result['summary'] ?? {});
      }
    } catch (e) {
      _pendingStats = {};
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final idToken = await getIdToken(context);
      final result = await _api.getMissingExtensionContacts(
        idToken: idToken,
        regionCode: widget.regionCode,
      );
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(result['contacts'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading contacts: $e')));
      }
    }
  }

  Future<void> _stageContact(
    Map<String, dynamic> contact,
    String action,
    String newPhone, {
    String? newName,
  }) async {
    try {
      final idToken = await getIdToken(context);
      await _api.stageFix(
        idToken: idToken,
        resourceName: contact['resource_name'],
        contactName: contact['name'],
        originalPhone: contact['phone'],
        newPhone: newPhone,
        action: action,
        newName: newName,
      );

      setState(() {
        _contacts.remove(contact);
        if (action == 'accept')
          _acceptCount++;
        else if (action == 'reject')
          _rejectCount++;
        else if (action == 'edit')
          _editCount++;

        final currentTotal = _pendingStats['total'] ?? 0;
        _pendingStats['total'] = currentTotal + 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error staging: $e')));
      }
    }
  }

  void _onSortSelected(dynamic value) {
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

  Future<void> _acceptAll() async {
    if (_contacts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept All?'),
        content: Text(
          'This will accept all ${_contacts.length} pending suggestions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: const Text(
              'Accept All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    int count = 0;
    final contactsToFix = List<Map<String, dynamic>>.from(_contacts);

    try {
      final idToken = await getIdToken(context);
      for (final contact in contactsToFix) {
        await _api.stageFix(
          idToken: idToken,
          resourceName: contact['resource_name'],
          contactName: contact['name'],
          originalPhone: contact['phone'],
          newPhone: contact['suggested'],
          action: 'accept',
        );
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Accepted $count suggestions'),
            backgroundColor: const Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      await _loadContacts();
      await _loadPendingStats();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => EditContactDialog(
        contact: contact,
        regionCode: widget.regionCode,
        onSave: (newName, newPhone) async {
          _stageContact(
            contact,
            'edit',
            newPhone,
            newName: newName != contact['name'] ? newName : null,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fixed ${contact['name']}'),
                backgroundColor: const Color(0xFF667eea),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _navigateToPendingChanges() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PendingChangesScreen(regionCode: widget.regionCode),
      ),
    );
    if (mounted) {
      await _loadContacts();
      await _loadPendingStats();
    }
  }

  void _handleSwipe(
    Map<String, dynamic> contact,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.right) {
      _stageContact(contact, 'accept', contact['suggested']);
    } else if (direction == CardSwiperDirection.left) {
      _stageContact(contact, 'reject', contact['phone']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionCount = _acceptCount + _rejectCount + _editCount;
    final backendTotal = _pendingStats['total'] as int? ?? 0;
    final displayCount = backendTotal > sessionCount
        ? backendTotal
        : sessionCount;

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
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text(
                'Phone Fixer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
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
          if (!_isSearching && displayCount > 0)
            TextButton.icon(
              onPressed: _navigateToPendingChanges,
              icon: const Icon(Icons.pending_actions, color: Colors.white),
              label: Text(
                '$displayCount',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          ControlToolbar(
            sortOption: _sortOption,
            isAscending: _isAscending,
            isSwipeView: _isSwipeView,
            onToggleView: () => setState(() => _isSwipeView = !_isSwipeView),
            onSortSelected: _onSortSelected,
            onAcceptAll: _acceptAll,
            contactCount: _contacts.length,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                ? EmptyState(
                    totalProcessed: _acceptCount + _editCount,
                    onSyncPressed: displayCount > 0
                        ? _navigateToPendingChanges
                        : null,
                  )
                : _isSwipeView
                ? SwipeViewMode(
                    controller: _controller,
                    contacts: _filteredContacts,
                    acceptCount: _acceptCount,
                    rejectCount: _rejectCount,
                    editCount: _editCount,
                    onSwipe: _handleSwipe,
                    onEndReached: () => setState(() {}),
                    onEditPressed: _showEditDialog,
                  )
                : ListViewMode(
                    contacts: _filteredContacts,
                    acceptCount: _acceptCount,
                    rejectCount: _rejectCount,
                    editCount: _editCount,
                    onAccept: (c) => _stageContact(c, 'accept', c['suggested']),
                    onReject: (c) => _stageContact(c, 'reject', c['phone']),
                    onEdit: _showEditDialog,
                  ),
          ),
        ],
      ),
      floatingActionButton: (!_isSwipeView && displayCount > 0)
          ? FloatingActionButton.extended(
              onPressed: _navigateToPendingChanges,
              backgroundColor: const Color(0xFF10b981),
              icon: const Icon(Icons.cloud_upload),
              label: Text('Sync $displayCount Changes'),
            )
          : null,
    );
  }
}
