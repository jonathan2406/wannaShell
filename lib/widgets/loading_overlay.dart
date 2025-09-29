import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget que muestra un overlay de carga sobre el contenido
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                elevation: AppConstants.elevationL,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget de indicador de carga personalizado
class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const CustomLoadingIndicator({
    Key? key,
    this.size = 50.0,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Círculo exterior
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: _animation.value,
                      strokeWidth: 3.0,
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  // Círculo interior rotando
                  Positioned.fill(
                    child: Transform.rotate(
                      angle: _animation.value * 6.28, // 2π radianes
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: color,
                      ),
                    ),
                  ),
                  // Icono central
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.security,
                        size: widget.size * 0.4,
                        color: color,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: AppConstants.paddingM),
          Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Widget que muestra un shimmer effect para cargar listas
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ??
                BorderRadius.circular(AppConstants.borderRadiusM),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0.0),
              end: Alignment(1.0 + _animation.value, 0.0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Widget que muestra una lista de elementos shimmer
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({Key? key, this.itemCount = 5, this.itemHeight = 80.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.paddingS),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
          ),
          child: Row(
            children: [
              ShimmerLoading(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusS,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    ShimmerLoading(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 14,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusS,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    ShimmerLoading(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 12,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusS,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
