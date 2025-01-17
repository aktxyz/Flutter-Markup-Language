// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:flutter/material.dart';
import 'package:fml/widgets/table/table_model.dart';
import 'package:fml/widgets/table/header/table_header_model.dart';
import 'package:fml/widgets/table/header/cell/table_header_cell_view.dart';
import 'package:fml/widgets/widget/iwidget_view.dart';
import 'package:fml/widgets/widget/widget_state.dart';

class TableHeaderView extends StatefulWidget implements IWidgetView
{
  @override
  final TableHeaderModel? model;
  final double? height;
  final Map<int, double>? width;
  final Map<int, double>? padding;

  TableHeaderView(this.model, this.height, this.width, this.padding);

  @override
  State<TableHeaderView> createState() => _TableHeaderViewState();
}
//

class _TableHeaderViewState extends WidgetState<TableHeaderView>
{
  final double anchorWidth = 23;
  TableModel? tableModel;

  @override
  void initState()
  {
    super.initState();

    // CELL.Model cellModel = model;
    tableModel = widget.model!.findAncestorOfExactType(TableModel);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: builder);

  Widget builder(BuildContext context, BoxConstraints constraints)
  {
    // Check if widget is visible before wasting resources on building it
    if ((widget.model == null) || (widget.model!.visible == false)) return Offstage();

    // save system constraints
    onLayout(constraints);

    ///////////
    /* Cells */
    ///////////
    int i = 0;
    List<Widget> cells = [];
    List<Widget> dragHandles = [];
    double widthTotal = 0;
    for (var model in widget.model!.cells) {
      //////////
      /* Size */
      //////////
      double? height = widget.model?.height ?? widget.height;
      double? width  = (widget.width != null) && (widget.width!.containsKey(i)) ? widget.width![i] : 0;
      if ((width != null) && (widget.padding != null) && (widget.padding!.containsKey(i))) width += (widget.padding![i] ?? 0);

      //////////
      /* View */
      //////////
      Widget cell = TableHeaderCellView(model);

      ////////////
      /* Resize */
      ////////////
      Widget draghit   = Container(color: Colors.transparent, width: anchorWidth, height: height, child: Center(
          child: Container(width: 1, height: height, color: widget.model!.headerbordercolor ?? widget.model!.bordercolor ?? Theme.of(context).colorScheme.onSecondary.withOpacity(0.40))));
      Widget dragbox   = Container(color: Colors.transparent, width: anchorWidth, height: height);
      Widget draggable = MouseRegion(cursor: SystemMouseCursors.resizeLeftRight, child: Draggable(axis: Axis.horizontal, child: draghit, feedback: dragbox, onDragUpdate: (details) => onDrag(details, model.index)));

      if (widget.model!.draggable != false) {
        double widthPlusPrevious = width! + widthTotal - (anchorWidth / 2);
        widthTotal += width;
        if (widthPlusPrevious.isNegative) widthPlusPrevious = 0;
        cells.add(UnconstrainedBox(child: SizedBox(width: width > 0 ? width : null, height: height, child: cell)));
        dragHandles.add(Positioned(left: widthPlusPrevious,
            child: UnconstrainedBox(child: SizedBox(width: anchorWidth, height: height, child: draggable))));
      } else {
        cells.add(cell);
      }
      i++;
    }

    // We don't need the right edge handle
    if (dragHandles.isNotEmpty) {
      dragHandles.removeLast();
    }

    //////////
    /* View */
    //////////
    return Stack(children: [
      Row(children: cells, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize:  MainAxisSize.min),
      ...dragHandles,
    ]);
  }

  void onDrag(DragUpdateDetails details, int? cellIndex)
  {
    try
    {
      if (details.localPosition.dx > 0 || details.localPosition.dx.isNegative)
      {
        if (tableModel != null)
        {
          int    index          = cellIndex!;
          double position       = tableModel!.getCellPosition(index);
          RenderBox? tableObject = context.findRenderObject() as RenderBox?;
          Offset? tableGlobalPos = tableObject?.localToGlobal(Offset.zero);
          double offset         = details.localPosition.dx + anchorWidth - (tableGlobalPos?.dx ?? 0);
          double width          = offset - position;
          double cw             = tableModel!.getCellWidth(index) ?? 0;
          double cp             = tableModel!.getCellPadding(index) ?? 0;
          double difference     = width - (cw + cp);
          if(cw + difference < 0) difference = width - (width / (tableModel!.cellpadding.length));

          if (width > anchorWidth)
          {
            tableModel!.setCellWidth(index, width);
            tableModel!.setCellPadding(index, 0);
            tableModel!.setCellWidth(index + 1, (tableModel!.getCellWidth(index + 1)! + tableModel!.getCellPadding(index + 1)!) - (width - (cw + cp)));
            tableModel!.setCellPadding(index + 1, 0);
            
            for (int i = 0; i < tableModel!.widths.length; i++) {
              tableModel!.setCellWidth(i, tableModel!.getCellWidth(i)! + tableModel!.getCellPadding(i)!);
            }
            tableModel!.notifyListeners('width', width);
          }
        }
      }
    }
    catch(e) {Log().exception(e);}
  }

}
