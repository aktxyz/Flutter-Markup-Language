import 'package:flutter/material.dart';
import 'package:fml/helper/common_helpers.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/observable/binding.dart';
import 'package:fml/observable/observable.dart';
import 'package:fml/observable/observables/boolean.dart';
import 'package:fml/observable/observables/double.dart';
import 'package:fml/observable/observables/string.dart';
import 'package:fml/observable/scope.dart';
import 'package:fml/widgets/decorated/decorated_widget_model.dart';
import 'package:fml/widgets/viewable/viewable_widget_model.dart';
import 'package:fml/widgets/widget/widget_model.dart';
import 'package:xml/xml.dart';

enum LayoutType {none, row, column, stack}
enum VerticalAlignmentType {top, bottom, center, around, between, evenly}
enum HorizontalAlignmentType {left, right, center, around, between, evenly}

class LayoutModel extends DecoratedWidgetModel
{
  @required
  LayoutType get layoutType => throw(UnimplementedError);

  @required
  MainAxisSize get verticalAxisSize => throw(UnimplementedError);

  @required
  MainAxisSize get horizontalAxisSize => throw(UnimplementedError);

  // children with variable width
  List<ViewableWidgetModel> get variableWidthChildren => viewableChildren.where((child) => child.flex != null || child.pctWidth != null).toList();

  // children with variable height
  List<ViewableWidgetModel> get variableHeightChildren => viewableChildren.where((child) => child.flex != null || child.pctHeight != null).toList();

  // children with fixed width
  List<ViewableWidgetModel> get fixedWidthChildren => viewableChildren.where((child) => child.flex == null && child.pctWidth == null).toList();

  // children with fixed height
  List<ViewableWidgetModel> get fixedHeightChildren => viewableChildren.where((child) => child.flex == null && child.pctHeight == null).toList();

  /// layout style
  StringObservable? _layout;
  set layout(dynamic v)
  {
    if (_layout != null)
    {
      _layout!.set(v);
    }
    else if (v != null)
    {
      _layout = StringObservable(Binding.toKey(id, 'layout'), v, scope: scope, listener: onPropertyChange);
    }
  }
  String? get layout => _layout?.get()?.toLowerCase().trim();

  /// Center attribute allows a simple boolean override for halign and valign both being center. halign and valign will override center if given.
  BooleanObservable? _center;
  set center(dynamic v)
  {
    if (_center != null)
    {
      _center!.set(v);
    }
    else if (v != null)
    {
      _center = BooleanObservable(Binding.toKey(id, 'center'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get center => _center?.get() ?? false;

  /// wrap determines the widget, if layout is row or col, how it will wrap.
  BooleanObservable? _wrap;
  set wrap(dynamic v)
  {
    if (_wrap != null)
    {
      _wrap!.set(v);
    }
    else if (v != null)
    {
      _wrap = BooleanObservable(Binding.toKey(id, 'wrap'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get wrap => _wrap?.get() ?? false;

  /// Expand, which is true by default, tells the widget if it should shrink to its children, or grow to its parents constraints. Width/Height attributes will override expand.
  BooleanObservable? _expand;
  set expand(dynamic v)
  {
    if (_expand != null)
    {
      _expand!.set(v);
    }
    else if (v != null)
    {
      _expand = BooleanObservable(Binding.toKey(id, 'expand'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get expand => _expand?.get() ?? true;

  LayoutModel(WidgetModel? parent, String? id, {Scope?  scope}) : super(parent, id, scope: scope);

  static LayoutModel? fromXml(WidgetModel parent, XmlElement xml, {String? type})
  {
    LayoutModel? model;
    try {
      model = LayoutModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'box.Model');
      model = null;
    }
    return model;
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement? xml)
  {
    if (xml == null) return;

    // deserialize
    super.deserialize(xml);

    // properties
    layout = Xml.get(node: xml, tag: 'layout');
    center = Xml.get(node: xml, tag: 'center');
    wrap   = Xml.get(node: xml, tag: 'wrap');
    expand = Xml.get(node: xml, tag: 'expand');

    // expand=true is the same as setting the width and height to 100%
    // this is essentially a convenience setting
    if (expand)
    {
      // set width if not specified
      if (width  == null && pctWidth  == null)
      {
        // set width if not flex or
        // flex is not in the direction of the primary axis
        if (flex == null || (flex != null && layoutType != LayoutType.row)) width = "100%";
      }

      // set height if not specified
      if (height == null && pctHeight == null)
      {
        // set height if not flex or
        // flex is not in the direction of the primary axis
        if (flex == null || (flex != null && layoutType != LayoutType.column)) height = "100%";
      }
    }
  }

  @override
  List<Widget> inflate()
  {
    var id = this.id;

    print("inflate() => model id=$id");

    var layout = this.layoutType;
    var variableChildren = this.variableWidthChildren;
    var fixedChildren = (layout == LayoutType.row) ? this.fixedWidthChildren : this.fixedHeightChildren;

    List<Widget> views = [];
    for (var child in viewableChildren)
    {
      var view = child.getView();

      // if we have variable size children (% or flex)
      // register listeners on fixed size children
      if (variableChildren.isNotEmpty && fixedChildren.contains(child))
      {
        switch (layout)
        {
          case LayoutType.row:
            if (child.viewWidthObservable == null) child.viewWidthObservable = DoubleObservable(Binding.toKey(child.id, 'viewwidth'), null, scope: child.scope);
            child.viewWidthObservable!.registerListener(onWidthChange);
            child.viewWidth = null;
            break;

          case LayoutType.column:
            if (child.viewHeightObservable == null) child.viewHeightObservable = DoubleObservable(Binding.toKey(child.id, 'viewheight'), null, scope: child.scope);
            child.viewHeightObservable!.registerListener(onHeightChange);
            child.viewHeight = 0;
            break;

          default:
            break;
        }
      }

      // add the view
      views.add(view);
    }
    return views;
  }

  @override
  void onLayoutComplete()
  {
    super.onLayoutComplete();

    var fixedChildren = (layoutType == LayoutType.row) ? this.fixedWidthChildren : this.fixedHeightChildren;

    // we need a callback to build if we have no fixed children
    if (fixedChildren.isEmpty)
    {
      switch (layoutType)
      {
        case LayoutType.row:
          onWidthChange(null);
          break;

        case LayoutType.column:
          onHeightChange(null);
          break;

        default:
          break;
      }
    }
  }

  void onWidthChange(Observable? child)
  {
    // layout can be performed when all fixed sized children have been laid out
    var unsizedChildren = fixedWidthChildren.where((child) => child.viewWidth == null);
    if (unsizedChildren.isEmpty)
    {
      print("onWidthChange() => id=$id child=${child?.key}");

      // calculate maximum space
      var maximum = calculateMaxWidth() ?? 0;

      var variableChildren = this.variableWidthChildren;
      var fixedChildren = this.fixedWidthChildren;

      // calculate fixed space
      double fixed = 0;
      for (var child in fixedChildren) fixed += (child.visible) ? (child.viewWidth ?? 0) : 0;

      // calculate usable space (max - fixed - padding)
      var usable = maximum - fixed;

      // set % sizing on variable children
      var free = usable;
      for (var child in variableChildren)
      {
        if (child.visible && child.pctWidth != null)
        {
          // calculate size from %
          int size = (usable * (child.pctWidth!/100)).floor();

          // must be 0 or greater
          if (size < 0) size = 0;

          // reduce free space
          free = free - size;

          // set the size
          if (child.width != size) child.setWidth(size.toDouble(), notify: true);
        }
      }

      // calculate sum of all flex values
      double flexsum = 0;
      for (var child in variableChildren) flexsum += (child.visible && child.pctWidth == null && child.flex != null && child.flex! > 0) ? child.flex! : 0;

      // set flex sizing on flexible children
      for (var child in variableChildren)
      {
        // % takes priority over flexibility
        // and would have been laid out above
        if (child.visible && child.pctWidth == null && child.flex != null && child.flex! > 0)
        {
          // calculate size from flex
          var size = ((child.flex! / flexsum) * free).floor();

          // must be 0 or greater
          if (size < 0) size = 0;

          // set the size
          if (child.width != size) child.setWidth(size.toDouble(), notify: true);
        }
      }
    }
  }

  void onHeightChange(Observable? child)
  {
    // layout can be performed when all fixed sized children have been laid out
    var unsizedChildren = fixedHeightChildren.where((child) => child.viewHeight == null);
    if (unsizedChildren.isEmpty)
    {
      print("onHeightChange() => model id=$id");

      // calculate maximum space
      var maximum = height ?? calculateMaxHeight() ?? 0;

      var variableChildren = this.variableHeightChildren;
      var fixedChildren = this.fixedHeightChildren;

      // calculate fixed space
      double fixed = 0;
      for (var child in fixedChildren) fixed += (child.visible) ? (child.viewHeight ?? 0) : 0;

      // calculate usable space (max - fixed - padding)
      var usable = maximum - fixed;

      // set % sizing on variable children
      var free = usable;
      for (var child in variableChildren)
      {
        if (child.visible && child.pctHeight != null)
        {
          // calculate size from %
          var size = (usable * (child.pctHeight!/100)).floor();

          // must be 0 or greater
          if (size < 0) size = 0;

          // reduce free space
          free = free - size;

          // set the size
          if (child.height != size) child.setHeight(size.toDouble(), notify: true);
        }
      }

      // calculate sum of all flex values
      double flexsum = 0;
      for (var child in variableChildren) flexsum += (child.visible && child.pctHeight == null && child.flex != null && child.flex! > 0) ? child.flex! : 0;

      // set flex sizing on flexible children
      for (var child in variableChildren)
      {
        // % takes priority over flexibility
        // and would have been laid out above
        if (child.visible && child.pctHeight == null && child.flex != null && child.flex! > 0)
        {
          // calculate size from flex
          var size = ((child.flex! / flexsum) * free).floor();

          // must be 0 or greater
          if (size < 0) size = 0;

          // set the size
          if (child.height != size) child.setHeight(size.toDouble(), notify: true);
        }
      }
    }
  }

  static LayoutType getLayoutType(String? layout, {LayoutType defaultLayout = LayoutType.none})
  {
    switch (layout?.toLowerCase().trim())
    {
      case 'col':
      case 'column':
        return LayoutType.column;

      case 'row':
        return LayoutType.row;

      case 'stack':
        return LayoutType.stack;

      default: return defaultLayout;
    }
  }
}
