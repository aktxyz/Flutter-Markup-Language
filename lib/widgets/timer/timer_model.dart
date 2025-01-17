// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:async';
import 'package:fml/log/manager.dart';
import 'package:xml/xml.dart';
import 'package:fml/widgets/widget/widget_model.dart'  ;
import 'package:fml/event/handler.dart' ;
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/common_helpers.dart';

class TimerModel extends WidgetModel
{
  // timer
  Timer? timer;
  bool started = false;

  // enabled
  BooleanObservable? _enabled;
  set enabled(dynamic v) {
    if (_enabled != null) {
      _enabled!.set(v);
    }
    else if (v != null)
    {
      _enabled = BooleanObservable(Binding.toKey(id, 'enabled'), v, scope: scope, listener: onTimerChange);
    }
  }
  bool get enabled => _enabled?.get() ?? true;

  // frequency in milliseconds
  IntegerObservable? _frequency;
  set frequency(dynamic frequency)
  {
    if (frequency == null) return;
    frequency = frequency.trim().toLowerCase();

    int factor = 1;
    if (frequency.endsWith('s')) factor = 1000;
    if (factor > 1) frequency = (frequency.length > 1) ? frequency.substring(0, frequency.length - 1) : null;

    if (S.isNumber(frequency))
    {
      int v = S.toInt(frequency)! * factor;
      if (v >= 0)
      {
        if (_frequency != null)
        {
          _frequency!.set(v);
        }
        else
        {
          _frequency = IntegerObservable(Binding.toKey(id, 'frequency'), v, scope: scope, listener: onTimerChange);
        }
      }
    }
  }
  int get frequency => _frequency?.get() ?? 0;
  
  // action
  StringObservable? _action;
  set action (dynamic v)
  {
    if (_action != null)
    {
      _action!.set(v);
    }
    else if (v != null)
    {
      _action = StringObservable(Binding.toKey(id, 'action'), v, scope: scope, lazyEval: true);
    }
  }
  String? get action => _action?.get();

  TimerModel(WidgetModel parent, String? id, {dynamic action, dynamic enabled, dynamic frequency}) : super(parent, id)
  {
    if (action    != null) this.action    = action;
    if (enabled   != null) this.enabled   = enabled;
    if (frequency != null) this.frequency = frequency;
  }

  static TimerModel? fromXml(WidgetModel parent, XmlElement xml, {String? type})
  {
    TimerModel? model;
    try
    {
      model = TimerModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);

      // start the timer
      model.start();
    }
    catch(e)
    {
      Log().exception(e, caller: 'timer.Model');
      model = null;
    }
    return model;
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement xml)
  {
    // deserialize 
    super.deserialize(xml);

    // properties
    action    = Xml.get(node: xml, tag: 'action');
    enabled   = Xml.get(node: xml, tag: 'enabled');
    frequency = Xml.get(node: xml, tag: 'frequency');
  }

  // start the timer
  void start()
  {
    started = true;
    if (frequency > 0 && enabled && (timer == null || !timer!.isActive)) timer = Timer(Duration(milliseconds: frequency), onTimer);
  }

  // stop the timer
  void stop()
  {
    if (timer != null && timer!.isActive) timer!.cancel();
  }

  Future<bool> onTimer() async
  {
    bool ok = true;

    // fire event
    if (!S.isNullOrEmpty(action)) ok = await EventHandler(this).execute(_action);

    // start a new timer
    start();

    return ok;
  }

  void onTimerChange(Observable observable)
  {
    // restart the timer
    if (started)
    {
      stop();
      start();
    }
  }

  @override
  void dispose()
  {
    // stop the timer
    stop();
    super.dispose();
  }
}