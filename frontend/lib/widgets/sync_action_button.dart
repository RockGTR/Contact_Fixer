import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/sync_state_provider.dart';

/// Neumorphic sync button with three states:
/// 1. Ready - Shows "Sync X Changes" with cloud icon
/// 2. Syncing - Shows "Syncing Contacts" with rotating cloud animation
/// 3. Complete - Shows stats (contacts synced, time saved)
class SyncActionButton extends StatefulWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const SyncActionButton({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  State<SyncActionButton> createState() => _SyncActionButtonState();
}

class _SyncActionButtonState extends State<SyncActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showingComplete = false;

  // Design system colors
  static const _accentGreen = Color(0xFF10b981);
  static const _accentGreenDark = Color(0xFF059669);
  static const _muted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStateProvider>(
      builder: (context, syncState, child) {
        final isSyncing = syncState.isSyncing;
        final isComplete = !syncState.isSyncing && syncState.pushed > 0;

        // Control animation
        if (isSyncing && !_controller.isAnimating) {
          _controller.repeat();
        } else if (!isSyncing && _controller.isAnimating) {
          _controller.stop();
        }

        // Show completion stats briefly
        if (isComplete && !_showingComplete) {
          _showingComplete = true;
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() => _showingComplete = false);
              syncState.reset();
            }
          });
        }

        return GestureDetector(
          onTap: isSyncing ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: _showingComplete ? 100 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSyncing
                    ? [_muted, _muted.withValues(alpha: 0.8)]
                    : [_accentGreen, _accentGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isSyncing ? _muted : _accentGreen).withValues(
                    alpha: 0.4,
                  ),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _showingComplete
                  ? _buildCompleteState(syncState)
                  : isSyncing
                  ? _buildSyncingState(syncState)
                  : _buildReadyState(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            'Sync ${widget.pendingCount} Changes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingState(SyncStateProvider syncState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated rotating sync icon
          RotationTransition(
            turns: _controller,
            child: const Icon(
              Icons.sync_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syncing Contacts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${syncState.current}/${syncState.total}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteState(SyncStateProvider syncState) {
    final timeSaved = (syncState.pushed * 15); // ~15 seconds per manual edit
    final timeSavedText = timeSaved > 60
        ? '${(timeSaved / 60).toStringAsFixed(1)} min'
        : '$timeSaved sec';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Sync Complete!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('${syncState.pushed}', 'Synced'),
              Container(width: 1, height: 24, color: Colors.white24),
              _buildStatItem(timeSavedText, 'Time Saved'),
              if (syncState.failed > 0) ...[
                Container(width: 1, height: 24, color: Colors.white24),
                _buildStatItem('${syncState.failed}', 'Failed'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
