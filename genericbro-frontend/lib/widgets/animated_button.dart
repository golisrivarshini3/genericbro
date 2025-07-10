import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final int index;
  final bool isEnabled;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.index,
    this.isEnabled = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (widget.index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.defaultPadding,
                vertical: AppTheme.defaultPadding / 2,
              ),
              decoration: AppTheme.buttonDecoration.copyWith(
                color: widget.isEnabled
                    ? AppTheme.buttonColor.withOpacity(_isHovered ? 1.0 : 0.95)
                    : Colors.grey.withOpacity(0.3),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.defaultPadding,
                  vertical: AppTheme.defaultPadding,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isEnabled
                            ? AppTheme.buttonIconColor
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(
                          AppTheme.defaultRadius - 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isEnabled
                                    ? AppTheme.buttonIconColor
                                    : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.defaultPadding),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: widget.isEnabled
                                  ? AppTheme.buttonIconColor
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color:
                          widget.isEnabled ? AppTheme.buttonIconColor : Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 