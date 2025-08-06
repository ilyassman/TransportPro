import 'package:flutter/material.dart';

class AnimatedTransitIndicator extends StatefulWidget {
  final String status;
  final double size;
  final bool isAnimated;

  const AnimatedTransitIndicator({
    super.key,
    required this.status,
    this.size = 50,
    this.isAnimated = true,
  });

  @override
  State<AnimatedTransitIndicator> createState() => _AnimatedTransitIndicatorState();
}

class _AnimatedTransitIndicatorState extends State<AnimatedTransitIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimated) {
      _animationController.repeat();
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

  IconData _getIcon() {
    switch (widget.status.toUpperCase()) {
      case 'EN_COURS':
        return Icons.play_arrow;
      case 'EN_TRANSIT':
        return Icons.local_shipping;
      case 'TERMINEE':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }

  String _getText() {
    switch (widget.status.toUpperCase()) {
      case 'EN_COURS':
        return 'DÉPART';
      case 'EN_TRANSIT':
        return 'EN TRANSIT';
      case 'TERMINEE':
        return 'TERMINÉ';
      default:
        return 'EN ATTENTE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isAnimated ? _bounceAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.isAnimated && widget.status.toUpperCase() == 'EN_TRANSIT' 
                ? _rotationAnimation.value * 2 * 3.14159 
                : 0.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _getBackgroundColor().withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: widget.size * 0.4,
                  ),
                  SizedBox(height: widget.size * 0.05),
                  Text(
                    _getText(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.size * 0.12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 