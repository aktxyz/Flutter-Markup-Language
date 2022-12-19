// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/widget/decorated_widget_model.dart';

import 'package:fml/widgets/widget/iViewableWidget.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:fml/widgets/column/column_view.dart';
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/helper_barrel.dart';

class ColumnModel extends DecoratedWidgetModel implements IViewableWidget
{
  /// Center attribute allows a simple boolean override for halign and valign both being center. halign and valign will override center if given.
  BooleanObservable? _center;
  set center(dynamic v) {
    if (_center != null) {
      _center!.set(v);
    } else if (v != null) {
      _center = BooleanObservable(Binding.toKey(id, 'center'), v,
          scope: scope, listener: onPropertyChange);
    }
  }
  bool get center => _center?.get() ?? false;

  /// wrap is a boolean that dictates if the widget will wrap or not.
  BooleanObservable? _wrap;
  set wrap(dynamic v) {
    if (_wrap != null) {
      _wrap!.set(v);
    } else if (v != null) {
      _wrap = BooleanObservable(Binding.toKey(id, 'wrap'), v,
          scope: scope, listener: onPropertyChange);
    }
  }
  bool get wrap => _wrap?.get() ?? false;

  /// shrinkwrap is the deprecated attribute, see `expand`
  BooleanObservable? _shrinkwrap;
  set shrinkwrap(dynamic v) {
    if (_shrinkwrap != null) {
      _shrinkwrap!.set(v);
    } else if (v != null) {
      _shrinkwrap = BooleanObservable(
          Binding.toKey(id, 'shrinkwrap'), v,
          scope: scope, listener: onPropertyChange);
    }
  }
  bool get shrinkwrap => _shrinkwrap?.get() ?? false;

  /// Expand, which is true by default, tells the widget if it should shrink to its children, or grow to its parents constraints. Width/Height attributes will override expand.
  //replaced shrinkwrap with expand.
  BooleanObservable? _expand;
  set expand(dynamic v) {
    if (_expand != null) {
      _expand!.set(v);
    } else if (v != null) {
      _expand = BooleanObservable(Binding.toKey(id, 'expand'), v,
          scope: scope, listener: onPropertyChange);
    }
  }
  bool get expand => _expand?.get() ?? true;

  ColumnModel(
    WidgetModel? parent,
    String? id, {
    dynamic halign,
    dynamic valign,
    dynamic expand,
    dynamic expanded,
  }) : super(parent, id) {
    this.halign = halign;
    this.valign = valign;
    this.expand = expand;
  }

  static ColumnModel? fromXml(WidgetModel? parent, XmlElement xml) {
    ColumnModel? model;
    try {
      /////////////////
      /* Build Model */
      /////////////////
      model = ColumnModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    } catch(e) {
      Log().exception(e,
           caller: 'column.Model');
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

    /// Attributes
    ///
    /// Layout Attributes
    wrap = Xml.get(node: xml, tag: 'wrap');
    center = Xml.get(node: xml, tag: 'center');
    expand = Xml.get(node: xml, tag: 'expand');

    // Deprecated Attributes
    shrinkwrap = Xml.get(node: xml, tag: 'shrinkwrap');
  }

  @override
  dispose() {
Log().debug('dispose called on => <$elementName id="$id">');
    super.dispose();
  }

  Widget getView({Key? key}) => ColumnView(this);
}
