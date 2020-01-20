import 'dart:async';

import 'package:clock/clock_progress.dart';
import 'package:clock/theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_control/core.dart';
import 'package:intl/intl.dart';

import 'core.dart';

class ClockControl extends BaseController with StateController {
  final date = StringControl();
  final hour = StringControl();
  final minute = StringControl();

  final hProgress = DoubleControl.inRange();
  final mProgress = DoubleControl.inRange();
  final sProgress = DoubleControl.inRange();

  ClockModel model;

  Timer _timer;
  DateTime _time;

  DynamicTheme get _theme => ControlProvider.get<DynamicTheme>();

  void _testTimelapse() async {
    _time = DateTime(2020);

    while (true) {
      date.value = DateFormat('EEE dd.MM.').format(_time);
      hour.value = DateFormat(model.is24HourFormat ? 'HH' : 'hh').format(_time);
      minute.value = DateFormat('mm').format(_time);

      hProgress.value = ((_time.hour >= 12 ? _time.hour - 12 : _time.hour) * 3600 + _time.minute * 60) / (12.0 * 3600.0);
      mProgress.value = (_time.minute * 60 + _time.second) / 3600.0;
      sProgress.value = _time.second / 60.0;

      await Future.delayed(Duration(seconds: 1));

      _time = _time.add(Duration(minutes: 15, seconds: 30));
      model.temperature = -20 + 60 * (_time.hour >= 12 ? 1.0 - hProgress.value : hProgress.value);
    }
  }

  void _testProgress() {
    _time = DateTime(2020, 1, 20, 4, 40, 42);

    date.value = DateFormat('EEE, MMM dd').format(_time);
    hour.value = DateFormat(model.is24HourFormat ? 'H' : 'h').format(_time);
    minute.value = DateFormat('mm').format(_time);

    hProgress.value = ((_time.hour >= 12 ? _time.hour - 12 : _time.hour) * 3600 + _time.minute * 60) / (12.0 * 3600.0);
    mProgress.value = (_time.minute * 60 + _time.second) / 3600.0;
    sProgress.value = _time.second / 60.0;

    model.temperature = -20 + 60 * (_time.hour >= 12 ? 1.0 - hProgress.value : hProgress.value);
    _theme.update(_time, model.temperature);
  }

  @override
  void onInit(Map args) {
    super.onInit(args);

    _time = DateTime.now();
    model = args.getArg<ClockModel>();

    assert(model != null);

    minute.subscribe((value) => _theme.updateDaytimeColor(_time));
    model.addListener(() {
      if (model.unit == TemperatureUnit.fahrenheit) {
        _theme.updateTemperatureColor((model.temperature - 32.0) * 5.0 / 9.0);
      } else {
        _theme.updateTemperatureColor(model.temperature);
      }
    });

    _tick();
    //_testProgress();
    //_testTimelapse();
  }

  void _tick() {
    _time = DateTime.now();

    date.value = DateFormat('EEE, MMM dd').format(_time);
    hour.value = DateFormat(model.is24HourFormat ? 'H' : 'h').format(_time);
    minute.value = DateFormat('mm').format(_time);

    hProgress.value = ((_time.hour >= 12 ? _time.hour - 12 : _time.hour) * 3600 + _time.minute * 60) / (12.0 * 3600.0);
    mProgress.value = (_time.minute * 60 + _time.second) / 3600.0;
    sProgress.value = _time.second / 60.0;

    _cancelTimer();

    _timer = Timer(Duration(seconds: 1) - Duration(milliseconds: _time.millisecond), _tick);
  }

  void _cancelTimer() {
    if (_timer != null) {
      if (_timer.isActive) {
        _timer.cancel();
      }
    }

    _timer = null;
  }

  @override
  void dispose() {
    super.dispose();

    _cancelTimer();
    hour.dispose();
    minute.dispose();
    hProgress.dispose();
    mProgress.dispose();
  }
}

class Clock extends SingleControlWidget<ClockControl> with ThemeProvider<ClockTheme> {
  Clock(ClockModel model) : super(args: model);

  @override
  ClockControl initController() => ClockControl();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Stack(
          children: <Widget>[
            //Seconds Progress
            FieldBuilder<double>(
              controller: controller.sProgress,
              builder: (context, value) => ClockProgress(
                colors: theme.daytimeGradient,
                stops: theme.gradientStops,
                progress: value,
              ),
            ),
            //Seconds Mask
            Container(
              constraints: BoxConstraints.expand(),
              margin: EdgeInsets.all(theme.secondsProgressInset),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(theme.deviceRadius)),
                color: theme.data.canvasColor,
              ),
            ),
            //Minutes Progress
            FieldBuilder<double>(
              controller: controller.mProgress,
              builder: (context, value) => ClockProgress(
                colors: theme.temperatureGradient,
                stops: theme.gradientStops,
                radius: theme.deviceRadius,
                padding: EdgeInsets.all(theme.secondsProgressInset),
                progress: value,
              ),
            ),
            //Minutes Mask
            Center(
              child: Container(
                width: theme.midSizeBorder,
                height: theme.midSizeBorder,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(theme.midSizeBorder * 0.5)),
                  color: theme.data.canvasColor,
                ),
              ),
            ),
            //Hours Progress
            FieldBuilder<double>(
              controller: controller.hProgress,
              builder: (context, value) => ClockProgress(
                colors: theme.daytimeGradient,
                stops: theme.gradientStops,
                radius: theme.deviceRadius,
                padding: EdgeInsets.all(theme.hoursProgressInset),
                progress: value,
              ),
            ),
            //Hours Mask
            Center(
              child: Container(
                width: theme.midSize,
                height: theme.midSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(theme.midSize * 0.5)),
                  color: theme.data.canvasColor,
                ),
              ),
            ),
            //Hours Text
            Column(
              children: <Widget>[
                Expanded(
                  child: Container(),
                ),
                Container(
                  height: theme.dynamicTitleStyle.fontSize,
                  child: FieldBuilderGroup(
                    controllers: [
                      controller.hour,
                      controller.minute,
                    ],
                    builder: (context, values) => TimeDisplay(
                      hour: values[0],
                      minute: values[1],
                      ofCenter: false,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        FieldBuilder<String>(
                          controller: controller.date,
                          builder: (context, value) => Text(
                            value,
                            style: font.subtitle,
                          ),
                        ),
                        SizedBox(
                          height: theme.paddingQuad,
                        ),
                        NotifierBuilder<ClockModel>(
                          model: controller.model,
                          builder: (context, value) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Image.asset(
                                  asset.icon(value.weatherString),
                                  width: theme.iconSizeLarge,
                                  height: theme.iconSizeLarge,
                                  color: font.body1.color,
                                ),
                                SizedBox(
                                  width: theme.paddingHalf,
                                ),
                                TemperatureDisplay(
                                  temperature: '${value.temperature.toStringAsFixed(0)}${value.unitString}',
                                  low: '${value.low.toStringAsFixed(0)}°',
                                  high: '${value.high.toStringAsFixed(0)}°',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TimeDisplay extends StatelessWidget with ThemeProvider<ClockTheme> {
  final String hour;
  final String minute;
  final bool ofCenter;

  TimeDisplay({
    Key key,
    this.hour,
    this.minute,
    this.ofCenter: false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    invalidateTheme(context);

    final titleStyle = theme.dynamicTitleStyle;

    if (ofCenter) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                hour,
                style: titleStyle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.paddingQuad),
            child: Text(
              ':',
              style: titleStyle,
            ),
          ),
          Expanded(
            child: Text(
              minute,
              style: titleStyle,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          hour,
          style: titleStyle,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.paddingQuad),
          child: Text(
            ':',
            style: titleStyle,
          ),
        ),
        Text(
          minute,
          style: titleStyle,
        ),
      ],
    );
  }
}

class TemperatureDisplay extends StatelessWidget with ThemeProvider {
  final String temperature;
  final String low;
  final String high;

  TemperatureDisplay({
    Key key,
    @required this.temperature,
    this.low,
    this.high,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    invalidateTheme(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          temperature,
        ),
        if (low != null || high != null)
          SizedBox(
            width: theme.paddingHalf,
          ),
        if (low != null)
          Image.asset(
            asset.icon('arrow_down'),
            width: theme.iconSize,
            height: theme.iconSize,
            color: font.body2.color,
          ),
        if (low != null)
          Text(
            low,
            style: font.body2,
          ),
        if (high != null)
          Image.asset(
            asset.icon('arrow_up'),
            width: theme.iconSize,
            height: theme.iconSize,
            color: font.body2.color,
          ),
        if (high != null)
          Text(
            high,
            style: font.body2,
          ),
      ],
    );
  }
}
