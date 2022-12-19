// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:flutter/material.dart';
import 'package:fml/widgets/widget/decorated_widget_model.dart';
import 'package:fml/widgets/widget/iViewableWidget.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:xml/xml.dart';
import 'package:fml/widgets/tooltip/tooltip_view.dart';
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/helper_barrel.dart';

class TooltipModel extends DecoratedWidgetModel implements IViewableWidget
{
  ///////////
  /* label */
  ///////////
  StringObservable? _label;

  set label(String? v) {
    if (_label != null) {
      _label!.set(v);
    } else if (v != null) {
      _label = StringObservable(Binding.toKey(id, 'label'), v,
          scope: scope, listener: onPropertyChange);
    }
  }
  String? get label => _label?.get();

  TooltipModel(
    WidgetModel parent,
    String? id, {
    dynamic label,
    dynamic color,
  }) : super(parent, id) {
    this.label = label;
    this.color = color;
  }

  static TooltipModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    TooltipModel? model;
    try
    {
      model = TooltipModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e, caller: 'tooltip.Model');
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
    label = Xml.get(node: xml, tag: 'label');
    if (label == null) label = Xml.get(node: xml, tag: 'text'); // backwards compatibility
    if (label == null) label = Xml.get(node: xml, tag: 'value'); // backwards compatibility
  }

  @override
  dispose()
  {
    Log().debug('dispose called on => <$elementName id="$id">');
    super.dispose();
  }

  Widget getView({Key? key}) => TooltipView(this);
}
