// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/observable/binding.dart';
import 'package:flutter/material.dart';
import 'package:fml/widgets/map/map_model.dart';
import 'package:fml/widgets/widget/iViewableWidget.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:fml/widgets/busy/busy_view.dart';
import 'package:fml/widgets/busy/busy_model.dart';
import 'package:fml/widgets/map/marker/map_marker_model.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatefulWidget
{
  final MapModel model;
  MapView(this.model) : super(key: ObjectKey(model));

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> implements IModelListener
{
  BusyView? busy;
  Future<MapModel>? future;
  bool startup = true;

  final mapController = MapController();
  List<Marker> markers = [];

  double? latitudeUpperBound;
  double? longitudeUpperBound;
  double? latitudeLowerBound;
  double? longitudeLowerBound;
  FlutterMap?  map;

  @override
  void initState()
  {
    super.initState();

    // register listener to the model
    widget.model.registerListener(this);

    // if the model contains any databrokers we fire them before building so we can bind to the data
    widget.model.initialize();
  }

  @override
  didChangeDependencies()
  {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(MapView oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.model != widget.model))
    {
      oldWidget.model.removeListener(this);
      widget.model.registerListener(this);
    }
  }

  @override
  void dispose()
  {
    widget.model.removeListener(this);
    super.dispose();
  }
  /// Callback function for when the model changes, used to force a rebuild with setState()
  onModelChange(WidgetModel model,{String? property, dynamic value})
  {
    if (this.mounted)
    {
      var b = Binding.fromString(property);
      if (b?.property == 'busy') return;
      if (property == 'busy') return;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context)
  {
       return LayoutBuilder(builder: builder);
  }

  Widget builder(BuildContext context, BoxConstraints constraint)
  {
    // Set Build Constraints in the [WidgetModel]
    widget.model.minwidth  = constraint.minWidth;
    widget.model.maxwidth  = constraint.maxWidth;
    widget.model.minheight = constraint.minHeight;
    widget.model.maxheight = constraint.maxHeight;

    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    // build the markers
    _buildMarkers();

    // build the map
    map = _buildMap();

    /// Busy / Loading Indicator
    if (busy == null) busy = BusyView(BusyModel(widget.model, visible: widget.model.busy, observable: widget.model.busyObservable));

    // map width
    var width = widget.model.width;
    if (width == null) width = widget.model.maxwidth;
    if ((width == null) || (width <= 0)) width = MediaQuery.of(context).size.width;

    // map height
    var height = widget.model.height;
    if (height == null) height = widget.model.maxheight;
    if ((height == null) || (height <= 0)) height = MediaQuery.of(context).size.height;

    // view
    dynamic view = Container(child: SizedBox(width: width, height: height, child: Stack(fit: StackFit.expand, children: [map!, busy!])));

    var constraints = widget.model.getConstraints();
    view = ConstrainedBox(child: view, constraints: BoxConstraints(
        minHeight: constraints.minHeight!,
        maxHeight: constraints.maxHeight!,
        minWidth: constraints.minWidth!,
        maxWidth: constraints.maxWidth!));
    
    return view;
  }

  FlutterMap? _buildMap()
  {
      try
      {
        // add map layers
        List<Widget> layers = [];
        widget.model.layers.forEach((url) => layers.add(TileLayer(urlTemplate: url, userAgentPackageName: 'fml.dev')));

        // default layer is openstreets
        if (widget.model.layers.isEmpty) layers.add(TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'fml.dev'));

        // add markers
        layers.add(MarkerLayer(markers: markers));

        // center point
        LatLng? center;
        if (widget.model.latitude != null && widget.model.longitude != null) center = LatLng(widget.model.latitude!, widget.model.longitude!);

        // zoom level
        double zoom = 16.0;
        if (widget.model.zoom > 0) zoom = widget.model.zoom;

        // map options
        MapOptions options = MapOptions(
          keepAlive: true,
          center: center,
          zoom: zoom,
          minZoom: 1,
          maxZoom: 20,
          //bounds: LatLngBounds(
          //  LatLng(51.74920, -0.56741),
          //  LatLng(51.25709, 0.34018),
          //),
          maxBounds: LatLngBounds(LatLng(-90, -180.0), LatLng(90.0, 180.0)));

        // map
        return FlutterMap(mapController: mapController, children: layers, options: options);
      }
      catch (e)
      {
        Log().exception("There was a problem building the map. Error is $e", caller: 'widget.map.View');
      }
      return null;
  }

  void _buildMarkers() async
  {
    try {
      ///////////////////
      /* Clear Markers */
      ///////////////////
      markers.clear();

      //////////////////
      /* Reset Bounds */
      //////////////////
      latitudeUpperBound  = null;
      latitudeLowerBound  = null;
      longitudeUpperBound = null;
      longitudeLowerBound = null;

      // build markers
      for (MapMarkerModel marker in widget.model.markers)
      {
        if (marker.latitude != null && marker.longitude != null)
        {
          var width = marker.width ?? 20;
          if (width < 5 || width > 200) width = 20;

          var height = marker.height ?? 20;
          if (height < 5 || height > 200) height = 20;

          markers.add(Marker(point: LatLng(marker.latitude!,  marker.longitude!), width: width, height: height, builder: (context) => _markerBuilder(marker.children)));
        }
      }
    }
    catch(e) {}

  }

  Widget _markerBuilder(List<WidgetModel>? children)
  {
    List<Widget> _children = [];
    if (children != null)
    children.forEach((model)
    {
      if (model is IViewableWidget) _children.add((model as IViewableWidget).getView());
    });

    Widget child = FlutterLogo();
    if (_children.length == 1) child = _children.first;
    if (_children.length >  1) child = Column(children: _children);
    return child;
  }

  void _showAll() async
  {
    if (map != null) {

    }

    //////////
    /* Busy */
    //////////
    widget.model.busy = false;
  }

  void _show(final double? latitude, final double? longitude) async
  {

    //////////
    /* Busy */
    //////////
    widget.model.busy = false;
  }
}