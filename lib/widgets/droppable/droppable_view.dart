// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:flutter/material.dart';
import 'package:fml/widgets/droppable/droppable_model.dart';
import 'package:fml/widgets/draggable/draggable_model.dart';
import 'package:fml/widgets/widget/iwidget_view.dart';
import 'package:fml/widgets/widget/widget_state.dart';

class DroppableView extends StatefulWidget implements IWidgetView
{
  @override
  final DroppableModel model;

  DroppableView(this.model) : super(key: ObjectKey(model));

  @override
  State<DroppableView> createState() => _DroppableViewState();
}


class _DroppableViewState extends WidgetState<DroppableView>
{
  @override
  Widget build(BuildContext context)
  {
    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    return DragTarget(onWillAccept: onWillAccept, onAccept: onAccept, builder: onBuild);
  }

  bool onWillAccept(DraggableModel? draggable)
  {
    if (draggable == null) return false;
    return widget.model.willAccept(draggable.id);
  }

  Future<bool> onAccept(DraggableModel draggable) async
  {
    draggable.busy = true;

    //////////
    /* Drop */
    //////////
    bool ok = await widget.model.onDrop(context, draggable);
    setState(() {});

    return ok;
  }

  Widget onBuild(context, List<dynamic> cd, List<dynamic> rd)
  {
    // build the child views
    List<Widget> children = widget.model.inflate();
    if (children.isEmpty) children.add(Container());

    return Stack(children: children);
  }
}
