// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/datasources/iDataSource.dart';
import 'package:fml/dialog/service.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/phrase.dart';
import 'package:fml/widgets/form/form_field_model.dart';
import 'package:fml/widgets/form/iFormField.dart';
import 'package:flutter/material.dart';

import 'package:fml/widgets/widget/iViewableWidget.dart';
import 'package:xml/xml.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:fml/widgets/switch/switch_view.dart';
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/helper_barrel.dart';

class SwitchModel extends FormFieldModel implements IFormField, IViewableWidget
{
  ///////////
  /* Width */
  ///////////
  @override
  double get width
  {
    return super.width ?? 56;
  }

  ///////////
  /* value */
  ///////////
  BooleanObservable? _value;
  set value (dynamic v)
  {
    if (_value != null)
    {
      _value!.set(v);
    }
    else if (v != null)
    {
      _value = BooleanObservable(Binding.toKey(id, 'value'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get value => _value?.get() ?? defaultValue ?? false;

  // question was answered
  bool get answered
  {
    if (value == true || value == false) return true;
    return false;
  }

  ///////////
  /* label */
  ///////////
  StringObservable? _label;
  set label(dynamic v) {
    if (_label != null) {
      _label!.set(v);
    } else if (v != null) {
      _label = StringObservable(Binding.toKey(id, 'label'), v,
          scope: scope, listener: onPropertyChange);
    }
  }
  String? get label => _label?.get();

  SwitchModel(
    WidgetModel parent,
    String? id, {
    String? type,
    dynamic visible,
    dynamic mandatory,
    dynamic editable,
    dynamic enabled,
    dynamic value,
    dynamic defaultValue,
    dynamic width,
    dynamic label,
    dynamic color,
    dynamic onchange,
    dynamic post,
  }) : super(parent, id)
  {
    if (mandatory    != null) this.mandatory  = mandatory;
    if (editable     != null) this.editable   = editable;
    if (enabled      != null) this.enabled    = enabled;
    if (value        != null) this.value      = value;
    if (defaultValue != null) this.defaultValue = defaultValue;
    if (width        != null) this.width      = width;
    if (label         != null) this.label       = label;
    if (color        != null) this.color      = color;
    if (onchange     != null) this.onchange   = onchange;
    if (post         != null) this.post       = post;

    this.alarming     = false;
    this.dirty        = false;
  }

  static SwitchModel? fromXml(WidgetModel parent, XmlElement xml, {String? type}) {
    SwitchModel? model;
    try
    {
      model = SwitchModel(parent, Xml.get(node: xml, tag: 'id'), type: type);
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'switch.Model');
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

    // set properties
    value = Xml.get(node: xml, tag: 'value');
    label = Xml.get(node: xml, tag: 'label');
  }

  bool onException(IDataSource source, Exception e)
  {
    DialogService().show(type: DialogType.error, title: phrase.error, description: e.toString());
    return super.onDataSourceException(source, e);
  }

  @override
  dispose()
  {
    Log().debug('dispose called on => <$elementName id="$id">');
    super.dispose();
  }

  Widget getView({Key? key}) => SwitchView(this);
}

class Suggestion {
  final dynamic text;

  Suggestion({this.text});
}