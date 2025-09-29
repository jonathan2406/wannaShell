import 'package:flutter/material.dart';
import '../models/session_status.dart';
import '../utils/constants.dart';

/// Widget que muestra el estado de una sesión como un chip colorido
class SessionStatusChip extends StatelessWidget {
  final SessionStatus status;
  final bool showIcon;
  final double? size;

  const SessionStatusChip({
    Key? key,
    required this.status,
    this.showIcon = true,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (status) {
      case SessionStatus.active:
        backgroundColor = AppConstants.activeColor;
        foregroundColor = Colors.white;
        icon = Icons.radio_button_checked;
        break;
      case SessionStatus.inactive:
        backgroundColor = AppConstants.inactiveColor;
        foregroundColor = Colors.white;
        icon = Icons.radio_button_unchecked;
        break;
      case SessionStatus.connecting:
        backgroundColor = AppConstants.connectingColor;
        foregroundColor = Colors.white;
        icon = Icons.sync;
        break;
      case SessionStatus.error:
        backgroundColor = AppConstants.errorSessionColor;
        foregroundColor = Colors.white;
        icon = Icons.error;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size != null ? size! * 0.5 : AppConstants.paddingS,
        vertical: size != null ? size! * 0.25 : AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          size != null ? size! * 0.75 : AppConstants.borderRadiusL,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              size: size ?? AppConstants.iconS,
              color: foregroundColor,
            ),
            SizedBox(width: size != null ? size! * 0.25 : AppConstants.paddingXS),
          ],
          Text(
            status.displayName.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: size != null ? size! * 0.6 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget animado que muestra el estado con efecto pulsante para sesiones activas
class AnimatedSessionStatusChip extends StatefulWidget {
  final SessionStatus status;
  final bool showIcon;
  final double? size;

  const AnimatedSessionStatusChip({
    Key? key,
    required this.status,
    this.showIcon = true,
    this.size,
  }) : super(key: key);

  @override
  State<AnimatedSessionStatusChip> createState() => _AnimatedSessionStatusChipState();
}

class _AnimatedSessionStatusChipState extends State<AnimatedSessionStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Solo animar si la sesión está activa o conectando
    if (widget.status == SessionStatus.active || widget.status == SessionStatus.connecting) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedSessionStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.status != widget.status) {
      if (widget.status == SessionStatus.active || widget.status == SessionStatus.connecting) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SessionStatusChip(
            status: widget.status,
            showIcon: widget.showIcon,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Widget que muestra estadísticas de estados de sesión
class SessionStatusStats extends StatelessWidget {
  final Map<SessionStatus, int> statusCounts;
  final VoidCallback? onTap;

  const SessionStatusStats({
    Key? key,
    required this.statusCounts,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado de Sesiones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Wrap(
                spacing: AppConstants.paddingS,
                runSpacing: AppConstants.paddingS,
                children: SessionStatus.values.map((status) {
                  final count = statusCounts[status] ?? 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SessionStatusChip(
                        status: status,
                        size: 12,
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        '$count',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
