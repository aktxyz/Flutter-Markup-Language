// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:math';

import 'package:fml/event/manager.dart';
import 'package:fml/log/manager.dart';
import 'package:flutter/material.dart';
import 'package:fml/phrase.dart';
import 'package:fml/event/event.dart' ;
import 'package:fml/widgets/widget/widget_model.dart'        ;
import 'package:fml/widgets/busy/busy_view.dart';
import 'package:fml/widgets/busy/busy_model.dart';
import 'package:fml/widgets/scrollshadow/scroll_shadow_view.dart';
import 'package:fml/widgets/scrollshadow/scroll_shadow_model.dart';
import 'package:fml/helper/measured.dart';
import 'package:fml/widgets/grid/grid_model.dart';
import 'package:fml/widgets/grid/item/grid_item_view.dart';
import 'package:fml/widgets/grid/item/grid_item_model.dart';
import 'package:fml/widgets/icon/icon_model.dart';
import 'package:fml/widgets/button/button_model.dart';
import 'package:xml/xml.dart';
import 'package:fml/helper/helper_barrel.dart';

class GridView extends StatefulWidget
{
  final GridModel model;
  GridView(this.model) : super(key: ObjectKey(model));

  @override
  _GridViewState createState() => _GridViewState();
}

class _GridViewState extends State<GridView> implements IModelListener
{
  BusyView? busy;
  bool startup = true;
  ScrollController? scroller;
  late ScrollShadowModel scrollShadow;

  @override
  void initState()
  {
    super.initState();

    scroller = ScrollController();

    widget.model.registerListener(this);

    // Clean
    widget.model.clean = true;

    // If the model contains any databrokers we fire them before building so we can bind to the data
    widget.model.initialize();
  }

  @override
  didChangeDependencies()
  {
    // register event listeners
    EventManager.of(widget.model)?.registerEventListener(EventTypes.scroll,  onScroll);
    EventManager.of(widget.model)?.registerEventListener(EventTypes.sort,    onSort);
    EventManager.of(widget.model)?.registerEventListener(EventTypes.export,  onExport);

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(GridView oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model)
    {
      // remove old event listeners
      EventManager.of(oldWidget.model)?.removeEventListener(EventTypes.scroll,  onScroll);
      EventManager.of(oldWidget.model)?.removeEventListener(EventTypes.sort,    onSort);
      EventManager.of(oldWidget.model)?.removeEventListener(EventTypes.export,  onExport);

      // register new event listeners
      EventManager.of(widget.model)?.registerEventListener(EventTypes.scroll,  onScroll);
      EventManager.of(widget.model)?.registerEventListener(EventTypes.sort,    onSort);
      EventManager.of(widget.model)?.registerEventListener(EventTypes.export,  onExport);

      oldWidget.model.removeListener(this);
      widget.model.registerListener(this);
    }
  }

  @override
  void dispose()
  {
    widget.model.removeListener(this);

    // remove event listeners
    EventManager.of(widget.model)?.removeEventListener(EventTypes.scroll,  onScroll);
    EventManager.of(widget.model)?.removeEventListener(EventTypes.sort,    onSort);
    EventManager.of(widget.model)?.removeEventListener(EventTypes.export,  onExport);

    scroller?.dispose();
    super.dispose();
  }

  void onSort(Event event) async
  {
    if (event.parameters != null)
    {
      String?  field     = event.parameters!.containsKey('field')     ? event.parameters!['field']     : null;
      String?  type      = event.parameters!.containsKey('type')      ? event.parameters!['type']      : 'string';
      String?  ascending = event.parameters!.containsKey('ascending') ? event.parameters!['ascending'] : 'true';
      if (!S.isNullOrEmpty(field)) widget.model.sort(field, type, S.toBool(ascending));
    }
  }

  void onExport(Event event) async
  {
    if (event.parameters!['format'] != 'print') {
      event.handled = true;

      final snackbar = SnackBar(content: Text(phrase.exportingData),duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating, elevation: 5);
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      await widget.model.export(raw: event.parameters!['raw'] == 'true');
    }
  }

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
          if (direction == 'left' || direction == 'right') {
            double offset = sc!.offset;
            double moveToPosition = offset + (direction == 'left' ? -distance : distance);
            sc.animateTo(moveToPosition, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
          }
          else if (direction == 'up' || direction == 'down') {
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

    //////////////////////
    /* Scroll Direction */
    //////////////////////
    dynamic direction = Axis.vertical;
    if (widget.model.direction == 'horizontal') direction = Axis.horizontal;

    /// Busy / Loading Indicator
    if (busy == null) busy = BusyView(BusyModel(widget.model, visible: widget.model.busy, observable: widget.model.busyObservable));

    var iconUp = IconModel(null, null, icon: 'keyboard_arrow_up');
    var scrollUpModel = ButtonModel(null, null, label: 'up', buttontype: "icon", color: Theme.of(context).highlightColor.withOpacity(0.3), onclick: "scroll('up', 360)", children: [iconUp]/*, visible: widget.model.moreUp*/);
    widget.model.moreUpObservable!.registerListener((observable) { scrollUpModel.visible = observable.get(); });

    var iconDown = IconModel(null, null, icon: 'keyboard_arrow_down');
    var scrollDownModel = ButtonModel(null, null, label: 'down', buttontype: "icon", color: Theme.of(context).highlightColor.withOpacity(0.3), onclick: "scroll('down', 360)", children: [iconDown]/*, visible: widget.model.moreDown*/);
    widget.model.moreDownObservable!.registerListener((observable) { scrollDownModel.visible = observable.get(); });

    var iconLeft = IconModel(null, null, icon: 'keyboard_arrow_left');
    var scrollLeftModel = ButtonModel(null, null, label: 'left', buttontype: "icon", color: Theme.of(context).highlightColor.withOpacity(0.3), onclick: "scroll('left', 360)", children: [iconLeft]/*, visible: widget.model.moreLeft*/);
    widget.model.moreLeftObservable!.registerListener((observable) { scrollLeftModel.visible = observable.get(); });

    var iconRight = IconModel(null, null, icon: 'keyboard_arrow_right');
    var scrollRightModel = ButtonModel(null, null, label: 'right', buttontype: "icon", color: Theme.of(context).highlightColor.withOpacity(0.3), onclick: "scroll('right', 360)", children: [iconRight]/*, visible: widget.model.moreRight*/);
    widget.model.moreRightObservable!.registerListener((observable) { scrollRightModel.visible = observable.get(); });

    //////////
    /* View */
    //////////
    List<Widget> children = [];
    if (widget.model.itemSize == null)
    {
      var model;
      try
      {
        // build prototype
        XmlElement? prototype = S.fromPrototype(widget.model.prototype, "${widget.model.id}-${0}");

        // build model
        model = GridItemModel.fromXml(this.widget.model, prototype);
      }
      catch(e)
      {
        model = widget.model.items.isNotEmpty ? widget.model.items.values.first : null;
      }

      var protoView    = model != null ? GridItemView(model: model) : Text('null');
      var measuredView = MeasuredView(UnconstrainedBox(child: protoView), onMeasuredItem);
      var offstageView = Offstage(child: measuredView);
      return offstageView;
    }

    Widget view = ListView.custom(scrollDirection: direction, controller: scroller, childrenDelegate: SliverChildBuilderDelegate((BuildContext context, int index) {return itemBuilder(context, index);}));

    ////////////////////////
    /* Constrain the View */
    ////////////////////////
    var width  = widget.model.width;
    var height = widget.model.height;
    if (constraints.maxHeight == double.infinity || constraints.maxHeight == double.negativeInfinity || height == null) height = widget.model.maxheight ?? constraints.maxHeight;
    if (constraints.maxWidth  == double.infinity || constraints.maxWidth  == double.negativeInfinity || width  == null) width  = widget.model.maxwidth ?? constraints.maxWidth;
    view = UnconstrainedBox(child: SizedBox(height: height, width: width, child: view));

    children.add(view);

    // Initialize scroll shadows to controller after building
    if (widget.model.scrollShadows == true)
    {
      scrollShadow = ScrollShadowModel(widget.model);
      children.add(ScrollShadowView(scrollShadow));
    }

    children.add(Center(child: busy));

    return Stack(children: children);
  }

  Widget? itemBuilder(BuildContext context, int index)
  {
    if (index > widget.model.items.length - 1) return null; // make sure list builder doesn't try and build past
    int count;
    double width = widget.model.maxwidth ?? widget.model.width ?? MediaQuery.of(context).size.width;
    double height = widget.model.maxheight ?? widget.model.height ?? MediaQuery.of(context).size.height;
    dynamic direction = Axis.vertical;
    if (widget.model.direction == 'horizontal') direction = Axis.horizontal;

    double? prototypeWidth;
    double? prototypeHeight;
    if (widget.model.items.length > 0)
    {
      prototypeWidth  = widget.model.items.entries.first.value.width ?? (widget.model.maxwidth ?? widget.model.width ?? MediaQuery.of(context).size.width) / (sqrt(widget.model.items.length) + 1);
      prototypeHeight = widget.model.items.entries.first.value.height ?? (widget.model.maxheight ?? widget.model.height ?? MediaQuery.of(context).size.height) / (sqrt(widget.model.items.length) + 1);
    }

    if (direction == Axis.vertical)
    {
      double cellwidth = prototypeWidth ?? widget.model.itemSize!.width;
      if (cellwidth == 0) cellwidth = 200;
      count = (width / cellwidth).floor();
    }
    else
    {
      double cellheight = prototypeHeight ?? widget.model.itemSize!.height;
      if (cellheight == 0) cellheight = 200;
      count = (height / cellheight).floor();
    }

    int start = (index * count);
    int end   = (start + count);

    if (start >= widget.model.items.length) return null;

    List<Widget> children = [];
    for (int i = start; i < end; i++)
    {
      if (i < widget.model.items.length)
      {
        var view = GridItemView(model: widget.model.items[i]);
        children.add(Expanded(child: SizedBox(width: prototypeWidth ?? widget.model.itemSize!.width, height: prototypeHeight ?? widget.model.itemSize!.height, child: view)));
      }
      else children.add(Expanded(child: Container()));
    }

    if (direction == Axis.vertical)
         return Row(children: children, mainAxisSize: MainAxisSize.min);
    else return Column(children: children, mainAxisSize: MainAxisSize.min);
  }

  void afterFirstLayout(BuildContext context)
  {

    ScrollController? controller = scroller;
    if (controller != null) _handleScrollNotification(ScrollUpdateNotification(metrics: FixedScrollMetrics(minScrollExtent: controller.position.minScrollExtent, maxScrollExtent: controller.position.maxScrollExtent, pixels: controller.position.pixels, viewportDimension: controller.position.viewportDimension, axisDirection: controller.position.axisDirection), context: context, scrollDelta: 0.0));
  }

  onMeasuredItem(Size size, {dynamic data})
  {
    setState(() {
      widget.model.itemSize = size;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification)
  {
    if (notification.metrics.hasViewportDimension)
    {
      if ((notification.metrics.axisDirection == AxisDirection.left) || (notification.metrics.axisDirection == AxisDirection.right))
      {
        widget.model.moreLeft = ((notification.metrics.maxScrollExtent > 0) && (((notification.metrics.atEdge == true) && (notification.metrics.pixels >  0)) || (notification.metrics.atEdge == false)));
        widget.model.moreRight = ((notification.metrics.maxScrollExtent > 0) && (((notification.metrics.atEdge == true) && (notification.metrics.pixels <= 0)) || (notification.metrics.atEdge == false)));
      }
      else
      {
        widget.model.moreUp = ((notification.metrics.maxScrollExtent > 0) && (((notification.metrics.atEdge == true) && (notification.metrics.pixels >  0)) || (notification.metrics.atEdge == false)));
        widget.model.moreDown = ((notification.metrics.maxScrollExtent > 0) && (((notification.metrics.atEdge == true) && (notification.metrics.pixels <= 0)) || (notification.metrics.atEdge == false)));
      }
    }
    return true;
  }

}