import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/sync_state_provider.dart';
import '../widgets/neumorphic_container.dart';

/// Neumorphic banner showing live sync progress
///
/// Design: Style Guide compliant with:
/// - 32px container radius, 16px inner elements
/// - Dual RGBA shadows (light top-left, dark bottom-right)
/// - Inset progress well with accent color fill
/// - Plus Jakarta Sans for heading, DM Sans for body
class SyncProgressBanner extends StatelessWidget {
  const SyncProgressBanner({super.key});

  // Design System Colors
  static const _background = Color(0xFFE0E5EC);
  static const _foreground = Color(0xFF3D4852);
  static const _muted = Color(0xFF6B7280);
  static const _accentGreen = Color(0xFF10b981);
  static const _accentAmber = Color(0xFFf59e0b);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStateProvider>(
      builder: (context, syncState, child) {
        if (!syncState.isSyncing) return const SizedBox.shrink();

        final isBackingOff = syncState.isBackingOff;
        final accentColor = isBackingOff ? _accentAmber : _accentGreen;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    // Neumorphic inset icon well
                    _buildIconWell(isBackingOff, accentColor),
                    const SizedBox(width: 16),
                    // Title and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBackingOff ? 'Rate Limited' : 'Syncing to Google',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _foreground,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            syncState.statusText,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Counter pill
                    _buildCounterPill(syncState, accentColor),
                  ],
                ),
                const SizedBox(height: 16),
                // Neumorphic inset progress bar
                _buildNeumorphicProgressBar(syncState, accentColor),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Neumorphic inset well for the icon
  Widget _buildIconWell(bool isBackingOff, Color accentColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        // Inset shadow effect
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(163, 177, 198, 0.6),
            offset: Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.8),
            offset: Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          isBackingOff ? Icons.hourglass_top_rounded : Icons.cloud_sync_rounded,
          color: accentColor,
          size: 24,
        ),
      ),
    );
  }

  /// Counter pill with accent coloring
  Widget _buildCounterPill(SyncStateProvider syncState, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${syncState.current}/${syncState.total}',
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: accentColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Neumorphic inset progress bar with smooth gradient fill
  Widget _buildNeumorphicProgressBar(
    SyncStateProvider syncState,
    Color accentColor,
  ) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(6),
        // Inset shadow - creates the "well" effect
        boxShadow: const [
          // Inner shadow simulation via inset
          BoxShadow(
            color: Color.fromRGBO(163, 177, 198, 0.5),
            offset: Offset(2, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.7),
            offset: Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Background track
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD1D9E6),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Animated fill with gradient
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              widthFactor: syncState.progress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated FractionallySizedBox for smooth progress transitions
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve,
    required this.widthFactor,
    required this.alignment,
    required this.child,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor =
        visitor(
              _widthFactor,
              widget.widthFactor,
              (value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}
