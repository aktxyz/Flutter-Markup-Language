// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/box/box_model.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:fml/helper/common_helpers.dart';

class StackModel extends BoxModel
{
  @override
  LayoutType layoutType = LayoutType.stack;

  @override
  String? get layout => "stack";

  @override
  bool isVerticallyExpanding() => height == null && heightPercentage == 100;

  @override
  bool isHorizontallyExpanding() => width == null && widthPercentage == 100;

  StackModel(WidgetModel parent, String? id) : super(parent, id);

  static StackModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    StackModel? model;
    try
    {
      // build model
      model = StackModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e, caller: 'stack.Model');
      model = null;
    }
    return model;
  }

  @override
  List<Widget> inflate()
  {
    // sort children by depth
    if (children != null) {
      children!.sort((a, b)
    {
      if(a.depth != null && b.depth != null) return a.depth?.compareTo(b.depth!) ?? 0;
      return 0;
    });
    }
    return super.inflate();
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement? xml)
  {
    // deserialize
    super.deserialize(xml);

    // sort the children
    children?.sort((a, b)
    {
      if(a.depth != null && b.depth != null) return a.depth?.compareTo(b.depth!) ?? 0;
      return 0;
    });
  }
}
