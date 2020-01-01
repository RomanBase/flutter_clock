import 'package:clock/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'clock.dart';
import 'core.dart';

const useCustomizer = false;

void main() {
  Control.init(
    debug: false,
    entries: {
      DynamicTheme: DynamicTheme(),
    },
    initializers: {
      ClockModel: (_) => ClockModel(),
    },
    theme: (context) => ClockTheme(context),
  );

  if (useCustomizer) {
    runApp(ClockCustomizer((model) {
      ControlProvider.set(value: model);

      return MainApp();
    }));
  } else {
    runApp(MainApp());
  }
}

class MainApp extends StatelessWidget {
  /// returns [ThemeMode] of Customizer's MaterialApp or [defaultValue].
  /// Just for testing without Customizer..
  ThemeMode customizerTheme(BuildContext context, ThemeMode defaultValue) {
    final customizer = context.findAncestorWidgetOfExactType<MaterialApp>();

    if (customizer == null) {
      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

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
          theme: theme.light,
          darkTheme: theme.dark,
        );
      },
    );
  }
}
