// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:async';
import 'package:fml/event/manager.dart';
import 'package:fml/log/manager.dart';
import 'package:flutter/material.dart';
import 'package:fml/event/event.dart'        ;
import 'package:fml/widgets/widget/widget_model.dart'       ;
import 'package:fml/widgets/busy/busy_model.dart';
import 'package:fml/widgets/busy/busy_view.dart';
import 'package:fml/widgets/list/list_model.dart';
import 'package:fml/widgets/list/item/list_item_view.dart';
import 'package:fml/widgets/list/item/list_item_model.dart';
import 'package:fml/widgets/text/text_model.dart';
import 'package:fml/helper/helper_barrel.dart';

class ListLayoutView extends StatefulWidget
{
  final ListModel model;
  ListLayoutView(this.model) : super(key: ObjectKey(model));

  @override
  _ListLayoutViewState createState() => _ListLayoutViewState();
}

class _ListLayoutViewState extends State<ListLayoutView> implements IModelListener, IEventScrolling
{
  Future<ListModel>? listViewModel;
  BusyView? busy;
  ScrollController? scroller;

  @override
  void initState()
  {
    super.initState();

    scroller = ScrollController();

    widget.model.registerListener(this);

    // If the model contains any databrokers we fire them before building so we can bind to the data
    widget.model.initialize();
  }

  @override
  didChangeDependencies()
  {
    // register event listeners
    EventManager.of(widget.model)?.registerEventListener(EventTypes.scroll,  onScroll);

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(ListLayoutView oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.model != widget.model))
    {
      oldWidget.model.removeListener(this);

      // remove old event listeners
      EventManager.of(oldWidget.model)?.removeEventListener(EventTypes.scroll,  onScroll);

      // register new event listeners
      EventManager.of(widget.model)?.registerEventListener(EventTypes.scroll,  onScroll);

      widget.model.registerListener(this);
    }
  }

  @override
  void dispose()
  {
    // remove model listener
    widget.model.removeListener(this);

    // remove event listeners
    EventManager.of(widget.model)?.removeEventListener(EventTypes.scroll,  onScroll);

    scroller?.dispose();
    super.dispose();
  }

  @override
  void onScroll(Event event) async
  {
    if (this.scroller != null) scroll(event, this.scroller);
    event.handled = true;
  }

  scroll(Event event, ScrollController? sc) async {
    try {
      if (event.parameters!.containsKey("direction") && event.parameters!.containsKey("pixels")) {
        String? direction = event.parameters!["direction"];
        double distance = double.parse(event.parameters!["pixels"]!);
        if (direction != null)
        {
          if (direction == 'left' || direction == 'right')
          {
            double offset = sc!.offset;
            double moveToPosition = offset + (direction == 'left' ? -distance : distance);
            sc.animateTo(moveToPosition, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
          }
          else if (direction == 'up' || direction == 'down')
          {
            double offset = sc!.offset;
            double moveToPosition = offset + (direction == 'up' ? -distance : distance);
            sc.animateTo(moveToPosition, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        }
      }
    }
    catch(e)
    {
      Log().error('onScroll Error: ');
      Log().exception(e, caller: 'table.View');
    }
  }
  /// Callback function for when the model changes, used to force a rebuild with setState()
  onModelChange(WidgetModel model,{String? property, dynamic value})
  {
    if (this.mounted) setState((){});
  }

  @override
  Widget build(BuildContext context)
  {
return LayoutBuilder(builder: builder);
  }

  Widget builder(BuildContext context, BoxConstraints constraints)
  {
    // Set Build Constraints in the [WidgetModel]
      widget.model.minwidth  = constraints.minWidth;
      widget.model.maxwidth  = constraints.maxWidth;
      widget.model.minheight = constraints.minHeight;
      widget.model.maxheight = constraints.maxHeight;

    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    /// Busy / Loading Indicator
    if (busy == null) busy = BusyView(BusyModel(widget.model, visible: widget.model.busy, observable: widget.model.busyObservable));

    ///////////////
    /* Direction */
    ///////////////
    dynamic direction = Axis.vertical;
    if (widget.model.direction == 'horizontal') direction = Axis.horizontal;

    List<Widget> children = [];

    //////////
    /* View */
    //////////
    Widget view = widget.model.collapsed == true
        ? SingleChildScrollView(child: ExpansionPanelList.radio(
          dividerColor: Theme.of(context).colorScheme.onInverseSurface,
          initialOpenPanelValue: 0,
          elevation: 2,
          expandedHeaderPadding: EdgeInsets.all(4),
          children: expansionItems(context)))
        : ListView.custom(scrollDirection: direction, controller: scroller, childrenDelegate: SliverChildBuilderDelegate((BuildContext context, int index) {return itemBuilder(context, index);}, childCount: widget.model.data?.length ?? widget.model.children?.length ?? 0));

    ////////////////////////
    /* Constrain the View */
    ////////////////////////
    double? width  = widget.model.width;
    double? height = widget.model.height;
    if (constraints.maxHeight == double.infinity || constraints.maxHeight == double.negativeInfinity || height == null) height = widget.model.maxheight ?? constraints.maxHeight;
    if (constraints.maxWidth  == double.infinity || constraints.maxWidth  == double.negativeInfinity || width  == null) width  = widget.model.maxwidth  ?? constraints.maxWidth;
    view = UnconstrainedBox(child: SizedBox(height: height, width: width, child: view));

    children.addAll([view, Center(child: busy)]);

    return Stack(children: children);
  }

  Widget? itemBuilder(BuildContext context, int index)
  {
    ListItemModel? model = widget.model.getItemModel(index);
    if (model == null) return null;
    return ListItemView(model: model, selectable: widget.model.selectable);
  }

  List<ExpansionPanelRadio> expansionItems(BuildContext context) {
    List<ExpansionPanelRadio> items = [];
    ListItemModel? itemModel;
    int index = 0;
    do {
      itemModel = widget.model.getItemModel(index++);
      if (itemModel != null) {
        var listItem = ListItemView(model: itemModel, selectable: widget.model.selectable);
        var title;
        if (!S.isNullOrEmpty(itemModel.title)) title = Text(itemModel.title!);
        else if (S.isNullOrEmpty(itemModel.title))
        {
          List<dynamic>? descendants = itemModel.findDescendantsOfExactType(TextModel);
          if (descendants != null && descendants.isNotEmpty) {
            int i = 0;
            while (i < descendants.length && descendants[i].value == null) i++;
            title = Text(descendants[i].value);
          }
        }
        else if (S.isNullOrEmpty(itemModel.title)) {
          title = Text(index.toString());
        }
        ListTile header = ListTile(title: title);
        var item = ExpansionPanelRadio(value: index, body: listItem, headerBuilder: (BuildContext context, bool isExpanded) => header, canTapOnHeader: true);
        items.add(item);
      }
    } while (itemModel != null);
    return items;
  }

}