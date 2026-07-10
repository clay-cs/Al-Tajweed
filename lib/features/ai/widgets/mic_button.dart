import 'package:flutter/material.dart';

import '../../../core/utils/extensions.dart';

/// Large microphone button with expanding pulse rings while recording.
class MicButton extends StatefulWidget {
  final bool recording;
  final bool enabled;
  final VoidCallback onTap;

  const MicButton({
    super.key,
    required this.recording,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didUpdateWidget(MicButton old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.recording && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.recording ? context.colors.error : context.colors.primary;

    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.recording) ...[
                  _ring(color, _pulse.value),
                  _ring(color, (_pulse.value + 0.5) % 1),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 26,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.recording
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ring(Color color, double t) {
    final size = 104 + t * 76;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity((1 - t) * 0.45),
          width: 2,
        ),
      ),
    );
  }
}
