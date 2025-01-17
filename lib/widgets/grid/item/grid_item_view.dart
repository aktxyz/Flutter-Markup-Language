// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:flutter/material.dart';
import 'package:fml/widgets/widget/iwidget_view.dart';
import 'package:fml/widgets/grid/item/grid_item_model.dart';
import 'package:fml/widgets/widget/widget_state.dart';

class GridItemView extends StatefulWidget implements IWidgetView
{
  @override
  final GridItemModel? model;
  GridItemView({this.model}) : super(key: ObjectKey(model));

  @override
  State<GridItemView> createState() => _GridItemViewState();
}

class _GridItemViewState extends WidgetState<GridItemView>
{
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: builder);

  Widget builder(BuildContext context, BoxConstraints constraints)
  {
    // Check if widget is visible before wasting resources on building it
    if ((widget.model == null) || (widget.model!.visible == false)) return Offstage();

    // get the children
    List<Widget> children = widget.model!.inflate();

    // default empty container
    if (children.isEmpty) children.add(Container());

    return Container(child: Center(child: children.length == 1 ? children[0] : Column(children: children, mainAxisSize: MainAxisSize.min)));
  }
}