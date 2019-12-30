import 'dart:math' as math;

import 'core.dart';

class ClockProgress extends StatefulWidget {
  final double progress;
  final double radius;
  final EdgeInsets padding;
  final List<Color> colors;
  final List<double> stops;
  final Widget child;

  const ClockProgress({
    Key key,
    this.progress: 0.25,
    this.radius: 0.0,
    this.padding: const EdgeInsets.all(0.0),
    this.colors: const [Colors.orange, Colors.blue],
    this.stops,
    this.child,
  }) : super(key: key);

  @override
  State createState() => _ClockProgressState();
}

class _ClockProgressState extends State<ClockProgress> with TickerProviderStateMixin {
  Tween<double> _progress;

  bool _reverse = false;

  AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _progress = Tween<double>(begin: 0.0, end: widget.progress);

    _progressController = AnimationController(duration: const Duration(seconds: 1), vsync: this);

    _progressController.addStatusListener((status) {
      if (_reverse && status == AnimationStatus.completed) {
        _reverse = false;
        _progress = Tween<double>(begin: 0.0, end: widget.progress);
        _progressController.forward(from: 0.0);
      }
    });

    _progressController.addListener(() => setState(() {}));

    _progressController.forward();
  }

  @override
  void didUpdateWidget(ClockProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress - oldWidget.progress < 0.0) {
      _reverse = true;
      _progress = Tween<double>(begin: _progress.end, end: 1.0);

      _progressController.forward(from: 0.0);
    }

    if (!_reverse) {
      _progress = Tween<double>(begin: oldWidget.progress, end: widget.progress);

      _progressController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      constraints: BoxConstraints.expand(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: CustomPaint(
          foregroundPainter: ClockProgressPainter(
            _progress.evaluate(_progressController),
            _reverse ? _progressController.value : 0.0,
            widget.colors,
            widget.stops,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class ClockProgressPainter extends CustomPainter {
  final double progress;
  final double reverseProgress;
  final List<Color> colors;
  final List<double> stops;

  ClockProgressPainter(
    this.progress,
    this.reverseProgress,
    this.colors,
    this.stops,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) {
      return;
    }

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.sqrt(center.dx * center.dx + center.dy * center.dy);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final startAngle = -math.pi * 0.5;
    final endAngle = math.pi * 2.0 * progress;

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: endAngle * reverseProgress,
        endAngle: endAngle,
        colors: colors,
        stops: stops,
        tileMode: TileMode.clamp,
        transform: GradientRotation(startAngle),
      ).createShader(rect);

    canvas.drawArc(
      rect,
      startAngle,
      endAngle,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(ClockProgressPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
