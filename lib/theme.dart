import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'core.dart';

class DynamicTheme extends BaseModel {
  final daytimeColor = ActionControl<Color>.broadcast();
  final temperatureColor = ActionControl<Color>.broadcast();

  ClockTheme get _theme => ThemeProvider.of<ClockTheme>();

  @override
  void init(Map args) {
    super.init(args);

    update(DateTime.now(), 22.0);
  }

  void update(DateTime time, double temperature) {
    updateDaytimeColor(time);
    updateTemperatureColor(temperature);
  }

  void updateDaytimeColor(DateTime time) {
    final stops = [
      0.0,
      4 / 24,
      6 / 24,
      8 / 24,
      12 / 24,
      18 / 24,
      20 / 24,
      22 / 24,
      1.0,
    ];
    daytimeColor.value = ColorUtil.lerpGradient(
      colors: _theme.dayTimeColors,
      stops: stops,
      t: (time.hour * 60 + time.minute) / (24 * 60),
    );
  }

  //TODO: api not eligible in competition..
  void updateTemperatureColor(double celsius) {
    // -15 - 0 - 25 - 35
    final min = 15.0;
    final sum = min + 25.0 + 10.0;
    final stops = [0.0, 15.0 / sum, 35.0 / sum, 1.0];
    final t = (celsius + min) / sum;

    final color = ColorUtil.lerpGradient(colors: _theme.temperatureColors, stops: stops, t: t);

    if (t < 0.0) {
      temperatureColor.value = color.darker(math.min(t.abs() * 5.0, 0.75), b: 0.5);
    } else if (t > 1.0) {
      temperatureColor.value = color.darker(math.min((t - 1.0) * 5.0, 0.75), r: 0.85);
    } else {
      temperatureColor.value = color;
    }
  }

  @override
  void dispose() {
    super.dispose();

    daytimeColor.dispose();
    temperatureColor.dispose();
  }
}

class ClockTheme extends ControlTheme {
  ThemeData get light => ThemeData(
        canvasColor: Color(0xFFC1C1C1),
        primaryColor: Color(0xFF00C1AA),
        fontFamily: fontName,
        textTheme: buildTextTheme(Color(0xFF313131)),
      );

  ThemeData get dark => ThemeData(
        canvasColor: Color(0xFF131313),
        primaryColor: Color(0xFF00A1A0),
        fontFamily: fontName,
        textTheme: buildTextTheme(Color(0xFFF1F1F1)),
      );

  TextTheme buildTextTheme(Color color) => TextTheme(
        title: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 64.0, letterSpacing: 7.5),
        subtitle: TextStyle(color: color.withOpacity(0.65), fontWeight: FontWeight.w300, fontSize: 14.0, letterSpacing: 1.5),
        body1: TextStyle(color: color),
        body2: TextStyle(color: color.withOpacity(0.65), fontWeight: FontWeight.w300, fontSize: 12.0),
      );

  ThemeMode get mode => ThemeMode.dark;

  double get gradientModeRatio => mode == ThemeMode.dark ? 0.65 : 0.35;

  List<Color> get primaryGradient => [data.canvasColor, primaryColor.darker(gradientModeRatio), primaryColor];

  List<Color> get daytimeGradient => [data.canvasColor, daytimeColor.value.darker(gradientModeRatio), daytimeColor.value];

  List<Color> get temperatureGradient => [data.canvasColor, temperatureColor.value.darker(gradientModeRatio), temperatureColor.value];

  final gradientStops = [0.0, 0.75, 1.0];

  final dayTimeColors = [
    Color(0xFFC1C1C1),
    Color(0xFF0025A1),
    Color(0xFFFC9500),
    Color(0xFF75C1FC),
    Color(0xFF00A1FC),
    Color(0xFF2575AC),
    Color(0xFFE13500),
    Color(0xFF0025A1),
    Color(0xFFC1C1C1),
  ];

  final temperatureColors = [
    Color(0xFF0030A1),
    Color(0xFFAfF1FF),
    Color(0xFFFFA100),
    Color(0xFFFF2500),
  ];

  final deviceRadius = 32.0;

  double get secondsProgressInset => kIsWeb ? 8.0 : 4.0;

  double get hoursProgressInset => (device.min - midSizeBorder) * 0.25;

  double get midSize => device.min * 0.65;

  double get midSizeBorder => midSize + 16.0;

  TextStyle get dynamicTitleStyle => font.title.copyWith(fontSize: midSize * 0.275, height: 1.0);

  @override
  final iconSize = 16.0;

  @override
  final fontName = 'Oswald';

  ClockTheme(BuildContext context) : super(context);

  DynamicTheme get _theme => ControlProvider.get<DynamicTheme>();

  ActionControlSub<Color> get daytimeColor => _theme.daytimeColor.sub;

  ActionControlSub<Color> get temperatureColor => _theme.temperatureColor.sub;
}

extension ColorUtil on Color {
  Color darker(double ratio, {double r: 1.0, double g: 1.0, double b: 1.0}) {
    ratio = 1.0 - ratio;

    return Color.fromARGB(
      alpha,
      _clamp(red * (ratio + ratio * (1.0 - r))),
      _clamp(green * (ratio + ratio * (1.0 - g))),
      _clamp(blue * (ratio + ratio * (1.0 - b))),
    );
  }

  Color lighter(double ratio, {double r: 1.0, double g: 1.0, double b: 1.0}) {
    return Color.fromARGB(
      alpha,
      _clamp(red + 255 * ratio * r),
      _clamp(green + 255 * ratio * g),
      _clamp(blue + 255 * ratio * b),
    );
  }

  int _clamp(double num) {
    return math.min(num.toInt(), 255);
  }

  static Color lerpGradient({@required List<Color> colors, List<double> stops, double t: 0.0}) {
    assert(colors.length > 1);
    assert(stops == null || colors.length == stops.length);

    t = t.clamp(0.0, 1.0);
    int index;

    if (stops != null) {
      index = stops.indexWhere((item) => item >= t) - 1;
      index = index.clamp(0, colors.length - 1);

      t = (t - stops[index]) / (stops[index + 1] - stops[index]);
    } else {
      index = (colors.length * t).floor();
      t = colors.length * t - index;
    }

    final a = colors[index];
    final b = colors[index + 1];

    return Color.lerp(a, b, t);
  }

  static List<Color> lerpColors(List<Color> a, List<Color> b, double t) {
    assert(a.length == b.length);

    final list = List<Color>();

    for (int i = 0; i < a.length; i++) {
      list.add(Color.lerp(a[i], b[i], t));
    }

    return list;
  }
}
