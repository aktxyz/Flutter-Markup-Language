// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/phrase.dart';
import 'package:flutter/material.dart';
import 'package:fml/helper/measured.dart';
import 'package:fml/event/event.dart'   ;
import 'package:fml/system.dart';
import 'package:fml/helper/helper_barrel.dart';
import 'package:fml/widgets/overlay/overlay_manager.dart';

class OverlayView extends StatefulWidget
{
  final String? id;
  final Widget child;

  final double? width;
  final double? height;

  final bool closeable;
  final bool resizeable;
  final bool draggable;
  final bool dismissable;
  final bool modal;
  final bool? pad;
  final bool? decorate;

  final double? dx;
  final double? dy;

  final Color? modalBarrierColor;

  late final _OverlayViewState? state;

  OverlayView({required this.child, this.id, this.width, this.height, this.dx, this.dy, this.resizeable = true, this.draggable = true, this.modal = false, this.closeable = true, this.dismissable = true, this.modalBarrierColor, this.pad, this.decorate}) : super();

  @override
  _OverlayViewState createState()
  {
    this.state = _OverlayViewState();
    return state!;
  }

  void close()
  {
    if (state != null) state!.onClose();
  }

  void dismiss()
  {
    if (state != null) state!.onDismiss();
  }

  bool get minimized
  {
    if (state != null) return state!.minimized;
    return false;
  }
}

class _OverlayViewState extends State<OverlayView>
{
  double padding = 15;

  double? dx;
  double? dy;

  double? width;
  double? height;

  late double maxHeight;
  late double maxWidth;

  bool minimized = false;
  bool maximized = false;

  double? originalDx;
  double? originalDy;
  double? originalWidth;
  double? originalHeight;

  double? lastDx;
  double? lastDy;
  double? lastWidth;
  double? lastHeight;

  @override
  void initState()
  {
    width  = widget.width;
    height = widget.height;
    dx     = widget.dx;
    dy     = widget.dy;
    super.initState();
  }

  @override
  didChangeDependencies()
  {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(OverlayView oldWidget)
  {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose()
  {
    super.dispose();
  }

  onMeasured(Size size, {dynamic data})
  {
    if (height == null) height = size.height;
    if (width == null)  width  = size.width;
    setState(() {});
  }

  bool closeHovered = false;
  bool minimizeHovered = false;

  @override
  Widget build(BuildContext context)
  {
    if (widget.pad == false) padding = 0;


    ColorScheme t = Theme.of(context).colorScheme;

    //////////
    /* Size */
    //////////
    if ((width == null) || (height == null)) return Offstage(child: Material(child: MeasuredView(UnconstrainedBox(child: widget.child), onMeasured)));

    /////////////////////
    /* Overlay Manager */
    /////////////////////
    OverlayManager? manager = context.findAncestorWidgetOfExactType<OverlayManager>();

    /* SafeArea */
    double sa = MediaQuery.of(context).padding.top;

    ///////////////////////////////
    /* Exceeds Width of Viewport */
    ///////////////////////////////
    maxWidth  = MediaQuery.of(context).size.width;
    if (width! > (maxWidth - (padding * 4))) width = (maxWidth - (padding * 4));
    if (width! <= 0) width = 50;

    ////////////////////////////////
    /* Exceeds Height of Viewport */
    ////////////////////////////////
    maxHeight = MediaQuery.of(context).size.height - sa;
    if (height! > (maxHeight - (padding * 4))) height = (maxHeight - (padding * 4));
    if (height! <= 0) height = 50;

    //////////
    /* Card */
    //////////
    Widget content = UnconstrainedBox(child: ClipRect(child: SizedBox(height: height, width: width, child: widget.child)));
    Widget card;
    if (widget.decorate == false)
         card = Card(child: content, margin: EdgeInsets.all(0.0), elevation: 0.0, borderOnForeground: false);
    else card = Card(child: content, margin: EdgeInsets.all(4.0), elevation: 25.0, borderOnForeground: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0)), side: BorderSide(color: Colors.transparent)));

    ////////////////////////
    /* Non-Minimized View */
    ////////////////////////
    if (minimized == false)
    {
      ////////////////
      /* Build View */
      ////////////////
      Widget close       = (widget.closeable == false)
          ? Container()
          : Padding(padding: EdgeInsets.only(left: 10), child: GestureDetector(onTap: () => onClose(),
            child: MouseRegion(cursor: SystemMouseCursors.click, onHover: (ev) => setState(() => closeHovered = true), onExit: (ev) => setState(() => closeHovered = false),
              child: UnconstrainedBox(child: SizedBox(height: 36, width: 36,
                child: Tooltip(message: phrase.close,    child: Icon(Icons.close, size: 32, color: !closeHovered ? t.surfaceVariant : t.onBackground)))))));

      Widget minimize    = ((widget.closeable == false)  || (widget.modal == true))
          ? Container()
          : Padding(padding: EdgeInsets.only(left: 10), child: GestureDetector(onTap: () => onMinimize(),
            child: MouseRegion(cursor: SystemMouseCursors.click, onHover: (ev) => setState(() => minimizeHovered = true), onExit: (ev) => setState(() => minimizeHovered = false),
              child: UnconstrainedBox(child: SizedBox(height: 36, width: 36,
                child: Tooltip(message: phrase.minimize, child: Icon(Icons.remove_circle, size: 32, color: !minimizeHovered ? t.surfaceVariant : t.onBackground)))))));

      Widget resize        = Icon(Icons.apps, size: 24, color: Colors.transparent);
      Widget resizeableBR  = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeUpLeftDownRight, child: resize), onPanUpdate: onResizeBR, onTapDown: onBringToFront);
      Widget resizeableBL  = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeUpRightDownLeft, child: resize), onPanUpdate: onResizeBL, onTapDown: onBringToFront);
      Widget resizeableTL  = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeUpLeftDownRight, child: resize), onPanUpdate: onResizeTL, onTapDown: onBringToFront);

      Widget resize2       = Container(width: isMobile ? 34 : 24, height: height);
      Widget resizeableL   = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeLeftRight, child: resize2), onPanUpdate: onResizeL, onTapDown: onBringToFront);
      Widget resizeableR   = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeLeftRight, child: resize2), onPanUpdate: onResizeR, onTapDown: onBringToFront);

      Widget resize3       = Container(width: width, height: isMobile ? 34 : 24);
      Widget resizeableT   = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeUpDown, child: resize3), onPanUpdate: onResizeT, onTapDown: onBringToFront);
      Widget resizeableB   = (widget.resizeable == false) ? Container() : GestureDetector(child: MouseRegion(cursor: SystemMouseCursors.resizeUpDown, child: resize3), onPanUpdate: onResizeB, onTapDown: onBringToFront);

      ////////////////
      /* Positioned */
      ////////////////
      if (dx == null) dx = (maxWidth / 2)  - ((width!  + (padding * 2)) / 2);
      if (dy == null) dy = (maxHeight / 2) - ((height! + (padding * 2)) / 2) + sa;

      ////////////////////////////
      /* Original Size/Position */
      ////////////////////////////
      if (originalDx == null)     originalDx = dx;
      if (originalDy == null)     originalDy = dy;
      if (originalWidth == null)  originalWidth  = width;
      if (originalHeight == null) originalHeight = height;

      ////////////////////////
      /* Last Size/Position */
      ////////////////////////
      if (lastDx == null)     lastDx = dx;
      if (lastDy == null)     lastDy = dy;
      if (lastWidth == null)  lastWidth  = width;
      if (lastHeight == null) lastHeight = height;

      //////////
      /* View */
      //////////
      Widget content = UnconstrainedBox(child: SizedBox(height: height! + (padding * 2), width: width! + (padding * 2),
          child: Stack(children: [
            Center(child: card),
            Positioned(child: resizeableL, top: 0, left: 0),
            Positioned(child: resizeableR, top: 0, right: 0),
            Positioned(child: resizeableT, top: 0, left: 0),
            Positioned(child: resizeableB, bottom: 0, left: 0),
            Positioned(child: resizeableTL, top: 0, left: 0),
            Positioned(child: resizeableBL, bottom: 0, left: 0),
            Positioned(child: resizeableBR, bottom: 0, right: 0),
            Positioned(child: minimize, top: 15, right: 50),
            Positioned(child: close, top: 15, right: 15)])));

      //////////////////////
      /* Remove from Park */
      //////////////////////
      if (manager != null) manager.unpark(widget);

      Widget curtain = GestureDetector(child: content, onDoubleTap: onRestoreTo, onTapDown: onBringToFront, onPanStart: (_) => onBringToFront(null), onPanUpdate: onDrag, onPanEnd: onDragEnd, behavior: HitTestBehavior.deferToChild);

      /////////////////
      /* Return View */
      /////////////////
      return Positioned(top: dy, left: dx, child: curtain);
    }

    ////////////////////
    /* Minimized View */
    ////////////////////
    else
    {
      //////////////////////
      /* Get Parking Spot */
      //////////////////////
      int? slot = 0;
      if (manager != null) slot = manager.park(widget);

      ////////////////
      /* Build View */
      ////////////////
      Widget scaled  = Card(margin: EdgeInsets.all(1), child: SizedBox(width: 100, height: 50, child: Padding(child: FittedBox(child: card), padding:EdgeInsets.all(5))), elevation: 5, color: t.secondary.withOpacity(0.50), borderOnForeground: false, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)), side: BorderSide(width: 2, color: t.primary)));
      Widget close   = (widget.closeable == false) ? Container() : Padding(padding: EdgeInsets.only(left: 10), child: GestureDetector(onTap: () => onClose(),  child: MouseRegion(cursor: SystemMouseCursors.click, child: UnconstrainedBox(child: SizedBox(height: 24, width: 24, child: Container(decoration: BoxDecoration(color: t.primaryContainer, shape: BoxShape.circle), child: Tooltip(message: phrase.close, child: Icon(Icons.close, size: 24, color: t.onPrimaryContainer))))))));
      Widget curtain = GestureDetector(onTap: onRestore, child: MouseRegion(cursor: SystemMouseCursors.click, child: SizedBox(width: 100, height: 50)));
      Widget view    = Stack(children: [scaled, curtain, Positioned(child: close, top: 15, right: 15)]);

      /////////////////
      /* Return View */
      /////////////////
      return Positioned(bottom: 10, left: 10 + (slot! * 110).toDouble(), child: view);
    }
  }

  bool _atOriginal()
  {
    return (originalWidth == width) && (originalHeight == height) && (originalDx == dx) && (originalDy == dy);
  }

  bool _atLast()
  {
    return (lastWidth == width) && (lastHeight == height) && (lastDx == dx) && (lastDy == dy);
  }

  onMinimize()
  {
    if (widget.closeable == false) return;
    setState(()
    {
      minimized = true;
      maximized = false;
    });
  }

  onMaximize()
  {
    if (widget.closeable == false) return;
    minimized = false;
    maximized = true;

    setState(()
    {
      minimized = false;
      maximized = true;
    });
  }

  onRestoreTo()
  {
    if (!_atOriginal()) return onRestoreToOriginal();
    if (!_atLast())     return onRestoreToLast();
  }

  onRestoreToOriginal()
  {
    setState(()
    {
      minimized = false;
      maximized = false;
      dx     = originalDx;
      dy     = originalDy;
      width  = originalWidth;
      height = originalHeight;
    });
  }

  onRestoreToLast()
  {
    setState(()
    {
      minimized = false;
      maximized = false;
      dx     = lastDx;
      dy     = lastDy;
      width  = lastWidth;
      height = lastHeight;
    });
  }


  onRestore()
  {
    if (widget.closeable == false) return;
    setState(()
    {
      minimized = false;
      maximized = false;
      onBringToFront(null);
    });
  }

  onClose()
  {
    if (widget.closeable == false) return;
    OverlayManager? overlay = context.findAncestorWidgetOfExactType<OverlayManager>();
    if (overlay != null)
    {
      overlay.unpark(widget);
      overlay.overlays.remove(widget);
      overlay.refresh();
    }
  }

  onDismiss()
  {
    if (widget.dismissable == false) return;
    OverlayManager? overlay = context.findAncestorWidgetOfExactType<OverlayManager>();
    if (overlay != null)
    {
      overlay.unpark(widget);
      overlay.overlays.remove(widget);
      overlay.refresh();
    }
  }

  onResizeBR(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((width  ?? 0) + details.delta.dx) < 50) return;
    if (((height ?? 0) + details.delta.dy) < 50) return;

    setState(()
    {
      width  = (width  ?? 0) + details.delta.dx;
      height = (height ?? 0) + details.delta.dy;

      lastDx     = dx;
      lastDy     = dy;

      lastWidth  = width;
      lastHeight = height;
    });
  }

  onResizeBL(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((width  ?? 0) - details.delta.dx) < 50) return;
    if (((height ?? 0) + details.delta.dy) < 50) return;

    setState(()
    {
      width  = (width  ?? 0) - details.delta.dx;
      height = (height ?? 0) + details.delta.dy;

      dx = dx! + details.delta.dx;
      lastDx     = dx;

      lastWidth  = width;
      lastHeight = height;
    });
  }

  onResizeTL(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((width  ?? 0) - details.delta.dx) < 50) return;
    if (((height ?? 0) + details.delta.dy) < 50) return;

    setState(()
    {
      width  = (width  ?? 0) - details.delta.dx;
      height = (height ?? 0) - details.delta.dy;

      dx = dx! + details.delta.dx;
      dy = dy! + details.delta.dy;

      lastDx     = dx;
      lastDy     = dy;

      lastWidth  = width;
      lastHeight = height;
    });
  }

  onResizeT(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((height ?? 0) - details.delta.dy) < 50) return;
    setState(()
    {
      height = (height ?? 0) - details.delta.dy;
      dy = dy! + details.delta.dy;
      lastDy     = dy;
      lastHeight = height;
    });
  }

  onResizeB(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((height ?? 0) + details.delta.dy) < 50) return;

    setState(()
    {
      height = (height ?? 0) + details.delta.dy;
      lastHeight = height;
    });
  }

  onResizeL(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((width  ?? 0) - details.delta.dx) < 50) return;
    setState(()
    {
      width  = (width  ?? 0) - details.delta.dx;
      dx = dx! + details.delta.dx;
      lastDx     = dx;
      lastWidth  = width;
    });
  }

  onResizeR(DragUpdateDetails details)
  {
    if (widget.resizeable == false) return;
    if (((width  ?? 0) + details.delta.dx) < 50) return;
    setState(()
    {
      width  = (width  ?? 0) + details.delta.dx;
      lastDx     = dx;
      lastWidth  = width;
    });
  }

  onDrag(DragUpdateDetails details)
  {
    if (widget.draggable == false) return;
    setState(()
    {
      dx = dx! + details.delta.dx;
      dy = dy! + details.delta.dy;
      if (widget.modal == true)
      {
        var viewport = MediaQuery.of(context).size;
        if (dx! < 0) dx = 0;
        if (dy! < 0) dy = 0;
        if (dx! + (width!  + (padding * 2)) > viewport.width)  dx = viewport.width  - (width!  + (padding * 2));
        if (dy! + (height! + (padding * 2)) > viewport.height) dy = viewport.height - (height! + (padding * 2));
      }

      lastDx = dx;
      lastDy = dy;
      lastWidth  = width;
      lastHeight = height;
    });
  }

  onDragEnd(DragEndDetails details)
  {
    if ((widget.draggable == false) || (widget.modal == true)) return;
    var viewport = MediaQuery.of(context).size;
    bool minimize = (dx! + width! < 0) || (dx! > viewport.width) || (dy! + height! < 0) || (dy! > viewport.height);
    if (minimize)
    {
      dx     = originalDx;
      dy     = originalDy;
      lastDx = originalDx;
      lastDy = originalDy;
      onMinimize();
    }
  }

  onBringToFront(TapDownDetails? details)
  {
    OverlayManager? overlay = context.findAncestorWidgetOfExactType<OverlayManager>();
    if (overlay != null) overlay.bringToFront(widget);
  }

  void onCloseEvent(Event event)
  {
    String? id = (event.parameters != null)  ? event.parameters!['id'] : null;
    if ((S.isNullOrEmpty(id)) || (id == widget.id))
    {
      event.handled = true;
      onClose();
    }
  }
}
