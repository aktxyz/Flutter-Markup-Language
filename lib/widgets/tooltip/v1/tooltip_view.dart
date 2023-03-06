// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/system.dart';
import 'package:flutter/material.dart';
import 'package:fml/widgets/widget/iViewableWidget.dart';
import 'package:fml/widgets/tooltip/v1/tooltip_model.dart';
import 'package:fml/widgets/widget/iWidgetView.dart';
import 'package:fml/helper/common_helpers.dart';
import 'package:fml/widgets/widget/widget_state.dart';

class TooltipView extends StatefulWidget implements IWidgetView
{
  final List<Widget> children = [];
  final TooltipModel model;
  TooltipView(this.model) : super(key: ObjectKey(model));

  @override
  _TooltipViewState createState() => _TooltipViewState();
}

class _TooltipViewState extends WidgetState<TooltipView>
{
  @override
  Widget build(BuildContext context)
  {
    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    //////////////////
    /* Add Children */
    //////////////////
    List<Widget> children = [];
    if (widget.model.children != null)
      widget.model.children!.forEach((model)
      {
        if (model is IViewableWidget) {
          children.add((model as IViewableWidget).getView());
        }
      });


    Widget child = children.length == 1 ? children[0] : Column(children: children, mainAxisSize: MainAxisSize.min);
    if (S.isNullOrEmpty(widget.model.label))
      return child;

    dynamic activator;
    if (isMobile)
      activator = child;
    else activator = MouseRegion(cursor: SystemMouseCursors.click, child: child);
    Widget tooltip = Tooltip(
        message: widget.model.label ?? '',
        decoration: BoxDecoration(color: widget.model.backgroundcolor ?? Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(22)),
        textStyle: TextStyle(fontSize: Theme.of(context).primaryTextTheme.bodySmall?.fontSize ?? 14, color:  widget.model.color ?? Theme.of(context).colorScheme.onBackground),
        child: activator);

    // tooltip = WidgetTooltip(widgetOverlay: Icon(Icons.import_contacts_sharp, color: Colors.pinkAccent), message: widget.model.label ?? '', textStyle: Theme.of(context).accentTextTheme.overline, child: activator);
    return tooltip;
  }
}