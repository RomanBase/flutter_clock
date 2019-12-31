import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'clock.dart';
import 'core.dart';

void main() {
  runApp(Builder(
    builder: (context) {
      Control.init(
        debug: false,
        initializers: {
          ClockModel: (_) => ClockModel(),
        },
        theme: (context) => ClockTheme(context),
      );

      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      return MainApp();
      return ClockCustomizer((model) {
        ControlProvider.set(value: model);

        return MainApp();
      });
    },
  ));
}

class MainApp extends StatelessWidget {
  ThemeMode customizerTheme(BuildContext context, ThemeMode defaultValue) {
    final customizer = context.findAncestorWidgetOfExactType<MaterialApp>();

    return customizer?.themeMode ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    return ControlBase(
      root: (BuildContext context) => Scaffold(
        body: Clock(ControlProvider.get<ClockModel>()),
      ),
      app: (BuildContext context, Key key, Widget home) {
        ClockTheme theme = ThemeProvider.of<ClockTheme>(context);

        return MaterialApp(
          key: key,
          home: home,
          title: 'Clock Competition',
          debugShowCheckedModeBanner: false,
          themeMode: customizerTheme(context, theme.mode),
          theme: ThemeData(
            canvasColor: Color(0xFFC1C1C1),
            primaryColor: theme.lightColor.lighter(0.75),
            primaryColorLight: theme.lightColor.lighter(0.50),
            primaryColorDark: theme.lightColor.lighter(0.85),
            fontFamily: theme.fontName,
            textTheme: ClockTheme.buildTextTheme(Color(0xFF313131)),
          ),
          darkTheme: ThemeData(
            canvasColor: Color(0xFF131313),
            primaryColor: theme.darkColor.darker(0.25),
            primaryColorLight: theme.darkColor,
            primaryColorDark: theme.darkColor.darker(0.35),
            fontFamily: theme.fontName,
            textTheme: ClockTheme.buildTextTheme(Color(0xFFF1F1F1)),
          ),
        );
      },
    );
  }
}

class ClockTheme extends ControlTheme {
  static TextTheme buildTextTheme(Color color) => TextTheme(
        title: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 64.0, letterSpacing: 7.5),
        subtitle: TextStyle(color: color.withOpacity(0.65), fontWeight: FontWeight.w300, fontSize: 14.0, letterSpacing: 1.5),
        body1: TextStyle(color: color),
        body2: TextStyle(color: color.withOpacity(0.65), fontWeight: FontWeight.w300, fontSize: 12.0),
      );

  final gradientStops = [0.0, 0.75, 1.0];

  final Color lightColor = Color(0xFF00FFFF);
  final Color darkColor = Color(0xFF00AAAA);

  ThemeMode get mode => ThemeMode.dark;

  double get gradientModeRatio => mode == ThemeMode.dark ? 0.65 : 0.35;

  List<Color> get progressGradient => [data.canvasColor, primaryColor.darker(gradientModeRatio), primaryColor];

  List<Color> get progressGradientLight => [data.canvasColor, primaryColorLight.darker(gradientModeRatio), primaryColorLight];

  List<Color> get progressGradientDark => [data.canvasColor, primaryColorDark.darker(gradientModeRatio), primaryColorDark];

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
}

extension ColorExtension on Color {
  Color darker(double ratio) {
    ratio = 1.0 - ratio;

    return Color.fromARGB(
      alpha,
      _clamp(red * ratio),
      _clamp(green * ratio),
      _clamp(blue * ratio),
    );
  }

  Color lighter(double ratio) {
    return Color.fromARGB(
      alpha,
      _clamp(red + 255 * ratio),
      _clamp(green + 255 * ratio),
      _clamp(blue + 255 * ratio),
    );
  }

  int _clamp(double num) {
    return math.min(num.toInt(), 255);
  }
}
