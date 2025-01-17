// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:flutter/material.dart';
import 'package:fml/widgets/view/view_model.dart';
import 'package:fml/widgets/widget/iwidget_view.dart';
import 'package:fml/widgets/widget/widget_state.dart';

class View extends StatefulWidget implements IWidgetView
{
  @override
  final ViewModel model;

  View(this.model) : super(key: ObjectKey(model));

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends WidgetState<View>
{
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: builder);

  Widget builder(BuildContext context, BoxConstraints constraints)
  {
    // save system constraints
    onLayout(constraints);

    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    // build the child views
    List<Widget> children = widget.model.inflate();
    if (children.isEmpty) children.add(Container());

    // view
    var view = children.length == 1 ? children[0] : SizedBox(height: widget.model.calculatedMaxHeightOrDefault, child: Column(children: children, mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min));
    return view;
  }
}
