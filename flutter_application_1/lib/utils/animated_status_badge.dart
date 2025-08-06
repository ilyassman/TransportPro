import 'package:flutter/material.dart';

class AnimatedStatusBadge extends StatefulWidget {
  final String status;
  final String text;
  final IconData icon;
  final double size;
  final bool isAnimated;

  const AnimatedStatusBadge({
    super.key,
    required this.status,
    required this.text,
    required this.icon,
    this.size = 60,
    this.isAnimated = true,
  });

  @override
  State<AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimated) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.status.toUpperCase()) {
      case 'EN_COURS':
        return const Color(0xFFF59E0B); // Orange
      case 'EN_TRANSIT':
        return const Color(0xFF3B82F6); // Bleu
      case 'TERMINEE':
        return const Color(0xFF10B981); // Vert
      case 'EN_ATTENTE':
        return const Color(0xFF6B7280); // Gris
      default:
        return const Color(0xFF6B7280); // Gris par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isAnimated ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _getBackgroundColor().withOpacity(0.3),
                  blurRadius: widget.isAnimated ? 8 + (_pulseAnimation.value * 4) : 8,
                  spreadRadius: widget.isAnimated ? 2 + (_pulseAnimation.value * 1) : 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size * 0.3,
                ),
                SizedBox(height: widget.size * 0.05),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 