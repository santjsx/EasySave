import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Tactile primary microphone voice trigger button.
/// Diameter is locked at exactly 96dp to satisfy Rule 4.
/// Includes visual pulsing animation rings during [isListening] active capture.
class EasyMicrophoneButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const EasyMicrophoneButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<EasyMicrophoneButton> createState() => _EasyMicrophoneButtonState();
}

class _EasyMicrophoneButtonState extends State<EasyMicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulsingController;

  @override
  void initState() {
    super.initState();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isListening) {
      _pulsingController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EasyMicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulsingController.isAnimating) {
      _pulsingController.repeat();
    } else if (!widget.isListening && _pulsingController.isAnimating) {
      _pulsingController.stop();
      _pulsingController.reset();
    }
  }

  @override
  void dispose() {
    _pulsingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isListening ? 'వింటున్నాము' : 'పేరు చెప్పండి', // Telugu vocal descriptors
      child: GestureDetector(
        onTap: _handleTap,
        child: SizedBox(
          width: AppSpacing.micTouchTarget, // Locked at 96.0 dp
          height: AppSpacing.micTouchTarget,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing concentric ripple waves behind the main button circle
              if (widget.isListening)
                AnimatedBuilder(
                  animation: _pulsingController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        _buildPulseRing(scale: 1.0 + (_pulsingController.value * 0.6), opacity: 0.4 - (_pulsingController.value * 0.3)),
                        _buildPulseRing(scale: 1.0 + (_pulsingController.value * 1.1), opacity: 0.2 - (_pulsingController.value * 0.2)),
                      ],
                    );
                  },
                ),
              // Main Microphone Core Button Circle
              Container(
                width: 96.0,
                height: 96.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isListening ? AppDesignColors.success : AppDesignColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isListening ? AppDesignColors.success : AppDesignColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 16.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 48.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing({required double scale, required double opacity}) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: 96.0,
          height: 96.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isListening ? AppDesignColors.success : AppDesignColors.primary,
              width: 3.0,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.heavyImpact(); // Extra strong vibration feedback
    widget.onTap();
  }
}
