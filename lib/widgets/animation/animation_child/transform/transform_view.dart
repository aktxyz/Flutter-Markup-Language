// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fml/event/event.dart';
import 'package:fml/event/manager.dart';
import 'package:fml/helper/string.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/animation/animation_helper.dart';
import 'package:fml/widgets/animation/animation_child/transform/transform_model.dart';
import 'package:fml/widgets/widget/widget_model.dart';

/// Animation View
///
/// Builds the View from model properties
class TransformView extends StatefulWidget {
  final TransformModel model;
  final List<Widget> children = [];
  final Widget? child;
  final AnimationController? controller;

  TransformView(this.model, this.child, this.controller)
      : super(key: ObjectKey(model));

  @override
  TransformViewState createState() => TransformViewState();
}

class TransformViewState extends State<TransformView>
    with TickerProviderStateMixin
    implements IModelListener {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _xTranslateAnimation;
  late Animation<double> _yTranslateAnimation;
  late Animation<double> _zTranslateAnimation;
  bool soloRequestBuild = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.model.duration), reverseDuration: Duration(milliseconds: widget.model.reverseduration ?? widget.model.duration,));
      if(widget.model.controllerValue == 1 && widget.model.runonce == true) {
        _controller.animateTo(widget.model.controllerValue, duration: Duration());

        if (widget.model.autoplay == true && _controller.isAnimating != true) start();
      }
      _controller.addStatusListener((status) {
        _animationListener(status);
      });
      soloRequestBuild = true;
    } else {
      _controller = widget.controller!;
    }

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  didChangeDependencies() {
    // register model listener
    widget.model.registerListener(this);

    if(soloRequestBuild) {
      // register event listeners
      EventManager.of(widget.model)?.registerEventListener(
          EventTypes.animate, onAnimate);
      EventManager.of(widget.model)?.registerEventListener(
          EventTypes.reset, onReset);
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TransformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.model != widget.model)) {
      // re-register model listeners
      oldWidget.model.removeListener(this);
      widget.model.registerListener(this);

      if(soloRequestBuild) {
        // de-register event listeners
        EventManager.of(oldWidget.model)?.removeEventListener(
            EventTypes.animate, onAnimate);
        EventManager.of(widget.model)?.removeEventListener(
            EventTypes.reset, onReset);

        // register event listeners
        EventManager.of(widget.model)?.registerEventListener(
            EventTypes.animate, onAnimate);
        EventManager.of(widget.model)?.registerEventListener(
            EventTypes.reset, onReset);

        _controller.duration = Duration(milliseconds: widget.model.duration);
        _controller.reverseDuration = Duration(
            milliseconds: widget.model.reverseduration ??
                widget.model.duration);
      }
    }
  }

  @override
  void dispose() {

    if(soloRequestBuild) {
      stop();
      // remove controller
      _controller.dispose();
      // de-register event listeners
      EventManager.of(widget.model)?.removeEventListener(
          EventTypes.animate, onAnimate);
      EventManager.of(widget.model)?.removeEventListener(
          EventTypes.reset, onReset);
    }

    // remove model listener
    widget.model.removeListener(this);
    super.dispose();
  }

  /// Callback to fire the [_AnimationViewState.build] when the [AnimationModel] changes
  @override
  onModelChange(WidgetModel model, {String? property, dynamic value}) {
    if (mounted) setState(() {});
  }

  @override
Widget build(BuildContext context) => LayoutBuilder(builder: builder);

  Widget builder(BuildContext context, BoxConstraints constraints) {
    // Tween

    double begin = widget.model.begin;
    double end = widget.model.end;
    // default warp is 0.0015, 0 is no warping. This could potentially be made smarter
    double warp = (widget.model.warp ?? 15) / 10000;
    Curve curve = AnimationHelper.getCurve(widget.model.curve);

    List<String>? rotateFrom = widget.model.rotateFrom?.split(",");
    List<String>? rotateTo = widget.model.rotateTo.split(",");
    List<String>? translateFrom = widget.model.translateFrom?.split(",");
    List<String>? translateTo = widget.model.translateTo.split(",");

    //start, end, center
    Alignment align =
    AnimationHelper.getAlignment(widget.model.align?.toLowerCase());



    if (begin != 0.0 || end != 1.0) {
      curve = Interval(
        begin,
        end,
        // the style curve to pass.
        curve: curve,
      );
    }

    _xAnimation = Tween<double>(
      begin: S.toDouble(rotateFrom?.elementAt(0)) ?? 0,
      end: S.toDouble(rotateTo.elementAt(0)) ?? 0,
    ).animate(CurvedAnimation(
      curve: curve,
      parent: _controller,
    ));
    _yAnimation = Tween<double>(
      begin: S.toDouble(rotateFrom?.elementAt(1)) ?? 0,
      end: S.toDouble(rotateTo.elementAt(1)) ?? 0,
    ).animate(CurvedAnimation(
      curve: curve,
      parent: _controller,
    ));
    _xTranslateAnimation = Tween<double>(
      begin: S.toDouble(translateFrom?.elementAt(0)) ?? 0,
      end: S.toDouble(translateTo.elementAt(0)) ?? 0,
    ).animate(CurvedAnimation(
      curve: curve,
      parent: _controller,
    ));
    _yTranslateAnimation = Tween<double>(
      begin: S.toDouble(translateFrom?.elementAt(1)) ?? 0,
      end: S.toDouble(translateTo.elementAt(1)) ?? 0,
    ).animate(CurvedAnimation(
      curve: curve,
      parent: _controller,
    ));
    _zTranslateAnimation = Tween<double>(
      begin: S.toDouble(translateFrom?.elementAt(2)) ?? 0,
      end: S.toDouble(translateTo.elementAt(2)) ?? 0,
    ).animate(CurvedAnimation(
      curve: curve,
      parent: _controller,
    ));


    // Build View
    Widget? view;

    view = Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, warp)
        ..rotateY(pi * _yAnimation.value * 2)
        ..rotateX(pi * _xAnimation.value * 2)
        ..translate(_xTranslateAnimation.value, _yTranslateAnimation.value, _zTranslateAnimation.value),
      alignment: align,
      //origin: Offset(0, 0),
      child: widget.child,
    );

    // Return View
    return view;
  }

  void onAnimate(Event event) {
    if (event.parameters == null) return;

    String? id = (event.parameters != null) ? event.parameters!['id'] : null;
    if ((S.isNullOrEmpty(id)) || (id == widget.model.id)) {
      bool? enabled = (event.parameters != null)
          ? S.toBool(event.parameters!['enabled'])
          : true;
      if (enabled != false) {
        start();
      } else {
        stop();
      }
      event.handled = true;
    }
  }

  void onReset(Event event) {
    String? id = (event.parameters != null) ? event.parameters!['id'] : null;
    if ((S.isNullOrEmpty(id)) || (id == widget.model.id)) {
      reset();
    }
  }

  void reset() {
    try {
      _controller.reset();
      widget.model.controllerValue = 0;
    } catch (e) {
      Log().debug('$e');
    }
  }

  void start() {
    try {
      if(widget.model.hasrun) return;
      if (_controller.isCompleted) {
        if(widget.model.runonce) widget.model.hasrun = true;
        _controller.reverse();
        widget.model.controllerValue = 0;
        widget.model.onStart(context);
      } else if (_controller.isDismissed) {
        _controller.forward();
        widget.model.controllerValue = 1;
        if(widget.model.runonce) widget.model.hasrun = true;
        widget.model.onStart(context);
      } else {
        _controller.forward();
        widget.model.controllerValue = 1;
        if(widget.model.runonce) widget.model.hasrun = true;
        widget.model.onStart(context);
      }

    } catch (e) {
      Log().debug('$e');
    }
  }

  void stop() {
    try {
      _controller.reset();
      widget.model.controllerValue = 0;
      _controller.stop();
    } catch (e) {
      Log().debug('$e');
    }
  }

  void _animationListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.model.controllerValue = 1;
      widget.model.onComplete(context);
    } else if  (status == AnimationStatus.dismissed) {
      widget.model.controllerValue = 0;
      widget.model.onDismiss(context);
    }
  }
}
