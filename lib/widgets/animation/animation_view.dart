// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:flutter/material.dart';
import 'package:fml/event/manager.dart';
import 'package:fml/log/manager.dart';

import 'package:fml/widgets/widget/iViewableWidget.dart';
import 'package:fml/widgets/widget/widget_model.dart'     ;
import 'package:fml/widgets/animation/animation_model.dart' as ANIMATION;
import 'package:fml/event/event.dart'      ;
import 'package:fml/helper/helper_barrel.dart';

/// Animation View
///
/// Builds the View from [ANIMATION.AnimationModel] properties
class AnimationView extends StatefulWidget
{
  final ANIMATION.AnimationModel model;
  final List<Widget> children = [];

  AnimationView(this.model) : super(key: ObjectKey(model));

  @override
  _AnimationViewState createState() => _AnimationViewState();
}

class _AnimationViewState extends State<AnimationView> with TickerProviderStateMixin implements IModelListener
{
  AnimationController? _controller;
  late Animation<double>   _animation;

  int  _loop    = 0;
  bool _stopped = false;

  @override
  void initState() 
  {
    super.initState();
  }

  @override
  didChangeDependencies()
  {
    // register event listeners
    EventManager.of(widget.model)?.registerEventListener(EventTypes.animate, onAnimate);

    // register model listener
    widget.model.registerListener(this);

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(AnimationView oldWidget) 
  {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.model != widget.model))
    {
      // de-register event listeners
      EventManager.of(oldWidget.model)?.removeEventListener(EventTypes.animate, onAnimate);

      // register event listeners
      EventManager.of(widget.model)?.registerEventListener(EventTypes.animate, onAnimate);

      // re-register model listeners
      oldWidget.model.removeListener(this);
      widget.model.registerListener(this);
    }
  }

  @override
  void dispose()
  {
    stop();

    // remove model listener
    widget.model.removeListener(this);

    // remove controller
    _controller?.dispose();

    // de-register event listeners
    EventManager.of(widget.model)?.removeEventListener(EventTypes.animate, onAnimate);

    super.dispose();
  }

  /// Callback to fire the [_AnimationViewState.build] when the [AnimationModel] changes
  onModelChange(WidgetModel model, {String? property, dynamic value}) {
    if (this.mounted) setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }

  Widget builder(BuildContext context, BoxConstraints constraints) {
    // Set Build Constraints in the [WidgetModel]
      widget.model.minwidth  = constraints.minWidth;
      widget.model.maxwidth  = constraints.maxWidth;
      widget.model.minheight = constraints.minHeight;
      widget.model.maxheight = constraints.maxHeight;

    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    ////////////////////
    /* Build Children */
    ////////////////////
    widget.children.clear();
    if (widget.model.children != null)
      widget.model.children!.forEach((model)
      {
        if (model is IViewableWidget) {
          widget.children.add((model as IViewableWidget).getView());
        }
      });
    if (widget.children.isEmpty) widget.children.add(Container());
    var child = widget.children.length == 1 ? widget.children[0] : Column(children: widget.children, crossAxisAlignment: CrossAxisAlignment.start);

    ////////////////
    /* Build View */
    ////////////////
    Widget? view;

    /////////////////////
    /* Animation Curve */
    /////////////////////
    Curve curve;
    ANIMATION.Curve? transitionCurve = S.toEnum(widget.model.transition, ANIMATION.Curve.values);
    switch (transitionCurve)
    {
      case ANIMATION.Curve.linear                 : curve = Curves.linear; break;
      case ANIMATION.Curve.decelerate             : curve = Curves.decelerate; break;
      case ANIMATION.Curve.fastLinearToSlowEaseIn : curve = Curves.fastLinearToSlowEaseIn; break;
      case ANIMATION.Curve.ease                   : curve = Curves.ease; break;
      case ANIMATION.Curve.easeIn                 : curve = Curves.easeIn; break;
      case ANIMATION.Curve.easeInToLinear         : curve = Curves.easeInToLinear; break;
      case ANIMATION.Curve.easeInSine             : curve = Curves.easeInSine; break;
      case ANIMATION.Curve.easeInQuad             : curve = Curves.easeInQuad; break;
      case ANIMATION.Curve.easeInCubic            : curve = Curves.easeInCubic; break;
      case ANIMATION.Curve.easeInQuart            : curve = Curves.easeInQuart; break;
      case ANIMATION.Curve.easeInQuint            : curve = Curves.easeInQuint; break;
      case ANIMATION.Curve.easeInExpo             : curve = Curves.easeInExpo; break;
      case ANIMATION.Curve.easeInCirc             : curve = Curves.easeInCirc; break;
      case ANIMATION.Curve.easeInBack             : curve = Curves.easeInBack; break;
      case ANIMATION.Curve.easeOut                : curve = Curves.easeOut; break;
      case ANIMATION.Curve.linearToEaseOut        : curve = Curves.linearToEaseOut; break;
      case ANIMATION.Curve.easeOutSine            : curve = Curves.easeOutSine; break;
      case ANIMATION.Curve.easeOutQuad            : curve = Curves.easeOutQuad; break;
      case ANIMATION.Curve.easeOutCubic           : curve = Curves.easeOutCubic; break;
      case ANIMATION.Curve.easeOutQuart           : curve = Curves.easeOutQuart; break;
      case ANIMATION.Curve.easeOutQuint           : curve = Curves.easeOutQuint; break;
      case ANIMATION.Curve.easeOutExpo            : curve = Curves.easeOutExpo; break;
      case ANIMATION.Curve.easeOutCirc            : curve = Curves.easeOutCirc; break;
      case ANIMATION.Curve.easeOutBack            : curve = Curves.easeOutBack; break;
      case ANIMATION.Curve.easeInOut              : curve = Curves.easeInOut; break;
      case ANIMATION.Curve.easeInOutSine          : curve = Curves.easeInOutSine; break;
      case ANIMATION.Curve.easeInOutQuad          : curve = Curves.easeInOutQuad; break;
      case ANIMATION.Curve.easeInOutCubic         : curve = Curves.easeInOutCubic; break;
      case ANIMATION.Curve.easeInOutQuart         : curve = Curves.easeInOutQuart; break;
      case ANIMATION.Curve.easeInOutQuint         : curve = Curves.easeInOutQuint; break;
      case ANIMATION.Curve.easeInOutExpo          : curve = Curves.easeInOutExpo; break;
      case ANIMATION.Curve.easeInOutCirc          : curve = Curves.easeInOutCirc; break;
      case ANIMATION.Curve.easeInOutBack          : curve = Curves.easeInOutBack; break;
      case ANIMATION.Curve.fastOutSlowIn          : curve = Curves.fastOutSlowIn; break;
      case ANIMATION.Curve.slowMiddle             : curve = Curves.slowMiddle; break;
      case ANIMATION.Curve.bounceIn               : curve = Curves.bounceIn; break;
      case ANIMATION.Curve.bounceOut              : curve = Curves.bounceOut; break;
      case ANIMATION.Curve.bounceInOut            : curve = Curves.bounceInOut; break;
      case ANIMATION.Curve.elasticIn              : curve = Curves.elasticIn; break;
      case ANIMATION.Curve.elasticOut             : curve = Curves.elasticOut; break;
      case ANIMATION.Curve.elasticInOut           : curve = Curves.elasticInOut; break;
      default                                     : curve = Curves.linear; break;
    }

    ////////////////////
    /* Animation Type */
    ////////////////////
    ANIMATION.Transitions? type = S.toEnum(widget.model.animation, ANIMATION.Transitions.values);
    if (type == null) type = ANIMATION.Transitions.fade;

    //////////////
    /* Duration */
    //////////////
    int duration = widget.model.duration;

    ///////////
    /* Tween */
    ///////////
    double from = widget.model.from;
    double to   = widget.model.to;

    switch (type)
    {
      case ANIMATION.Transitions.fade :
        _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
        _animation  = Tween(begin: from, end: to).animate(CurvedAnimation(parent: _controller!, curve: curve));
        if (_controller != null) {
          _controller!.removeStatusListener(_animationListener);
        }
        _controller!.addStatusListener(_animationListener);
        view = FadeTransition(opacity: _animation, child: child);
        break;

      case ANIMATION.Transitions.scale :
        _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
        _animation  = Tween(begin: from, end: to).animate(CurvedAnimation(parent: _controller!, curve: curve));
        if (_controller != null) {
          _controller!.removeStatusListener(_animationListener);
        }
        _controller!.addStatusListener(_animationListener);
        view = ScaleTransition(scale: _animation, child: child);
        break;

      case ANIMATION.Transitions.size:
        _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
        _animation  = Tween(begin: from, end: to).animate(CurvedAnimation(parent: _controller!, curve: curve));
        if (_controller != null) {
          _controller!.removeStatusListener(_animationListener);
        }
        _controller!.addStatusListener(_animationListener);
        view = SizeTransition(sizeFactor: _animation, axis: Axis.horizontal, child: child);
        break;

      case ANIMATION.Transitions.rotate :
        _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
        _animation  = Tween(begin: from, end: to).animate(CurvedAnimation(parent: _controller!, curve: curve));
        if (_controller != null) {
          _controller!.removeStatusListener(_animationListener);
        }
        _controller!.addStatusListener(_animationListener);
        view = RotationTransition(turns: _animation, child: child);
        break;

      case ANIMATION.Transitions.slide:
        _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
        _animation = CurvedAnimation(parent: _controller!, curve: curve);
        if (_controller != null) {
          _controller!.removeStatusListener(_animationListener);
        }
        _controller!.addStatusListener(_animationListener);
        var tween = Tween<Offset>(begin: Offset(from * widget.model.dx, from * widget.model.dy), end: Offset(to * widget.model.dx, to * widget.model.dy));
        view = SlideTransition(position: tween.animate(_animation), child: child);
        break;

      case ANIMATION.Transitions.position: // TODO fix
        _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
        _animation  = Tween(begin: from, end: to).animate(CurvedAnimation(parent: _controller!, curve: curve));
        if (_controller != null) {
          _controller!.removeStatusListener(_animationListener);
          _controller!.addStatusListener(_animationListener);
        }

        final Size biggest = constraints.biggest;
        const double small = 100;
        const double big   = 200;

        RelativeRectTween tween = RelativeRectTween(begin: RelativeRect.fromSize(Rect.fromLTWH(0, 0, small, small), biggest), end: RelativeRect.fromSize(Rect.fromLTWH(biggest.width - big, biggest.height - big, big, big), biggest));
        view = PositionedTransition(rect: tween.animate(CurvedAnimation(parent: _controller!, curve: curve)), child: child);
        break;
    }

    //////////////////////////
    /* Start the Controller */
    //////////////////////////
    if ((widget.model.autoplay == true) && (!_stopped)) start();

    /////////////////
    /* Return View */
    /////////////////
    return view;
  }

  void onAnimate(Event event)
  {
    if (event.parameters == null) return;

    String? id = (event.parameters != null) ? event.parameters!['id'] : null;
    if ((S.isNullOrEmpty(id)) || (id == widget.model.id))
    {
      bool? enabled = (event.parameters != null) ? S.toBool(event.parameters!['enabled']) : true;
      if (enabled != false)
           start();
      else stop();
      event.handled = true;
    }
  }

  void start()
  {
    try
    {
      if (_controller != null)
      {
        Log().debug('starting animation');
        _loop    = 0;
        _stopped = false;
        _controller!.reset();
        _controller!.forward();
      }
    }
    catch(e){}
  }

  void stop()
  {
    try
    {
      if (_controller != null)
      {
        _stopped = true;
        _controller!.reset();
        _controller!.stop();
      }
    }
    catch(e){}
  }

  void _animationListener(AnimationStatus status)
  {
    /////////////////////////
    /* Animation Complete? */
    /////////////////////////
    if (status == AnimationStatus.completed)
    {
      _loop++;
      if (_loop < widget.model.repeat || widget.model.repeat == 0)
      {
        ////////////
        /* Rewind */
        ////////////
        if (widget.model.reverse == true)
        {
          /////////////
          /* Reverse */
          /////////////
          if (_loop.isOdd)
          {
            _controller!.reverse().whenComplete(()
            {
              _loop++;
              (_loop < widget.model.repeat || widget.model.repeat == 0) ? _controller!.forward() : _controller!.stop();
            });
          }

          /////////////
          /* Forward */
          /////////////
          else _controller!.forward();
        }

        ///////////
        /* Reset */
        ///////////
        else
        {
          if (_loop < widget.model.repeat || widget.model.repeat == 0)
          {
            _controller!.reset();
            _controller!.forward();
          }
          else _controller!.stop();
        }
      }

      //////////
      /* Stop */
      //////////
      else _controller!.stop();
    }
  }
}