// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/layout/layout_model.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:fml/widgets/row/row_view.dart';
import 'package:fml/helper/common_helpers.dart';

class RowModel extends LayoutModel
{
  @override
  LayoutType layoutType = LayoutType.row;

  @override
  String? get layout => "row";

  @override
  MainAxisSize get verticalAxisSize => MainAxisSize.min;

  @override
  MainAxisSize get horizontalAxisSize => (expand && horizontallyConstrained) ? MainAxisSize.max : MainAxisSize.min;

  RowModel(WidgetModel parent, String? id) : super(parent, id);

  static RowModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    RowModel? model;
    try
    {
      // build model
      model = RowModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'row.Model');
      model = null;
    }
    return model;
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement? xml)
  {
    // deserialize 
    super.deserialize(xml);

    // expand=true is the same as setting the width to 100%
    // this is essentially a convenience setting
    if (expand && width == null && pctWidth == null && flex == null) width = "100%";
  }

  Widget getView({Key? key}) => getReactiveView(RowView(this));
}
