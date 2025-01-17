// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:async';
import 'dart:convert';
import 'package:fml/dialog/manager.dart';
import 'package:fml/event/event.dart';
import 'package:fml/event/manager.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/navigation/navigation_manager.dart';
import 'package:fml/widgets/box/box_model.dart';
import 'package:fml/widgets/widget/widget_model.dart'  ;
import 'package:fml/system.dart';
import 'package:fml/template/template.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:fml/widgets/header/header_model.dart';
import 'package:fml/widgets/footer/footer_model.dart';
import 'package:fml/widgets/drawer/drawer_model.dart';
import 'package:fml/event/handler.dart';
import 'package:fml/widgets/variable/variable_model.dart';
import 'package:fml/widgets/framework/framework_view.dart';
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/common_helpers.dart';

class FrameworkModel extends BoxModel implements IModelListener, IEventManager
{
  /// Event Manager Host
  final EventManager manager = EventManager();
  @override
  registerEventListener(EventTypes type, OnEventCallback callback, {int? priority}) => manager.register(type, callback, priority: priority);
  @override
  removeEventListener(EventTypes type, OnEventCallback callback) => manager.remove(type, callback);
  @override
  broadcastEvent(WidgetModel source, Event event) => manager.broadcast(this, event);
  @override
  executeEvent(WidgetModel source, String event) => manager.execute(this, event);

  HeaderModel?  header;
  FooterModel?  footer;
  DrawerModel?  drawer;

  List<String>? bindables;

  // disposed
  bool disposed = false;

  // xml node that created this template
  @override
  set element (XmlElement? element)
  {
    super.element = element;

    String? xml;
    if (element != null) xml = element.toXmlString(pretty: true);
    if (_template == null)
    {
      // we dont want the template to bindable
      // so set it to null then to its value
      // this defeats binding
      _template = StringObservable(Binding.toKey(id, 'template'), null, scope: scope);
      _template!.set(xml);
    }
    else {
      _template!.set(xml);
    }
  }

  // template
  StringObservable? _template;
  set template (dynamic v) {}
  String? get template => _template?.get();

  // key
  StringObservable? _key;
  set key (dynamic v)
  {
    if (_key != null)
    {
      _key!.set(v);
      if (element != null) Xml.setAttribute(element!, 'key', v);
    }
    else if (v != null)
    {
      _key = StringObservable(Binding.toKey(id, 'key'), v, scope: scope);
      if (element != null) Xml.setAttribute(element!, 'key', v);
    }
  }
  String? get key => _key?.get();

  // model is initialized
  BooleanObservable? _initialized;
  set initialized (dynamic v)
  {
    if (_initialized != null)
    {
      _initialized!.set(v);
    }
    else if (v != null)
    {
      _initialized = BooleanObservable(Binding.toKey(id, 'initialized'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get initialized => _initialized?.get() ?? false;

  // page stack index
  // This property indicates your position on the stack, 0 being the top
  IntegerObservable? get indexObservable => _index;
  IntegerObservable? _index;
  set index (dynamic v)
  {
    if (_index != null)
    {
      _index!.set(v);
    }
    else if (v != null)
    {
      _index = IntegerObservable(Binding.toKey(id, 'index'), v, scope: scope);
    }
  }
  int? get index
  {
    if (_index == null) return -1;
    return _index?.get();
  }

  // dependency key
  StringObservable? _dependency;
  set dependency (dynamic v)
  {
    if (_dependency != null)
    {
      _dependency!.set(v);
      if (element != null) Xml.setAttribute(element!, 'dependency', v);
    }
    else if (v != null)
    {
      _dependency = StringObservable(Binding.toKey(id, 'dependency'), v, scope: scope);
      if (element != null) Xml.setAttribute(element!, 'dependency', v);
    }
  }
  String? get dependency => _dependency?.get();

  // title
  StringObservable? _title;
  set title (dynamic v)
  {
    if (_title != null)
    {
      _title!.set(v);
    }
    else if (v != null)
    {
      _title = StringObservable(Binding.toKey(id, 'title'), v, scope: scope, listener: (_) => onTitleChange(context));
    }
  }
  String? get title => _title?.get();

  // version
  StringObservable? _version;
  set version (dynamic v)
  {
    if (_version != null)
    {
      _version!.set(v);
    }
    else if (v != null)
    {
      _version = StringObservable(Binding.toKey('TEMPLATE', 'version'), v, scope: scope);
    }
  }
  String? get version
  {
    return _version?.get();
  }

  // onstart
  StringObservable? _onstart;
  set onstart (dynamic v)
  {
    if (_onstart != null)
    {
      _onstart!.set(v);
    }
    else if (v != null)
    {
      _onstart = StringObservable(Binding.toKey(id, 'onstart'), v, scope: scope, lazyEval: true);
    }
  }
  String? get onstart
  {
    return _onstart?.get();
  }

  // orientation
  StringObservable? _orientation;
  set orientation (dynamic v)
  {
    if (_orientation != null)
    {
      _orientation!.set(v);
    }
    else if (v != null)
    {
      _orientation = StringObservable(Binding.toKey(id, 'orientation'), v, scope: scope);
    }
  }
  String? get orientation
  {
    if (_orientation == null) return null;
    return _orientation?.get();
  }

  // onreturn
  StringObservable? _onreturn;
  set onreturn (dynamic v)
  {
    if (_onreturn != null)
    {
      _onreturn!.set(v);
    }
    else if (v != null)
    {
      _onreturn = StringObservable(Binding.toKey(id, 'onreturn'), v, scope: scope, lazyEval: true);
    }
  }
  String? get onreturn
  {
    return _onreturn?.get();
  }

  String? templateName;

  // url
  StringObservable? _url;
  set url (dynamic v)
  {
    if (_url != null)
    {
      _url!.set(v);
    }
    else if (v != null)
    {
      _url = StringObservable(Binding.toKey(id, 'url'), v, scope: scope, listener: onPropertyChange);
    }
  }
  String? get url => _url?.get();

  // return parameters
  Map<String?, String> get parameters
  {
    Map<String?, String> myParameters = <String?, String>{};
    List<dynamic>? variables = findDescendantsOfExactType(VariableModel);
    if (variables != null) {
      for (var variable in variables) {
        VariableModel v = (variable as VariableModel);
        if (!S.isNullOrEmpty(v.returnas))
        {
          String? name  = v.returnas;
          String value = v.value ?? "";
          myParameters[name] = value;
        }
      }
    }
    return myParameters;
  }

  FrameworkModel(WidgetModel parent, String? id, {dynamic key, dynamic dependency, dynamic version, dynamic onstart, dynamic onreturn, dynamic orientation}) : super(parent, id, scope: Scope(id: id))
  {
    // model is initializing
    initialized = false;

    this.key         = key;
    this.dependency  = dependency;
    this.version     = version;
    this.onstart     = onstart;
    this.orientation = orientation;
    this.onreturn    = onreturn;
  }

  static FrameworkModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    FrameworkModel? model;
    try
    {
      model = FrameworkModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().debug(e.toString());
      model = null;
    }
    return model;
  }

  static FrameworkModel fromUrl(WidgetModel parent, String url, {String? id, bool? refresh, String? dependency})
  {
    FrameworkModel model = FrameworkModel(parent, id, dependency: dependency);
    model._load(url, refresh: refresh ?? false);
    return model;
  }

  Future _load(String url, {required bool refresh, String? dependency}) async
  {
    try
    {
      // parse the url
      Uri? uri = URI.parse(url);
      if (uri == null) throw('Error');

      // fetch the template
      Template template = await Template.fetch(url: url, parameters: uri.queryParameters, refresh: refresh);

      // get the xml
      var xml = template.document!.rootElement;

      // template requires rights?
      int? requiredRights = S.toInt(Xml.attribute(node: xml, tag: 'rights'));
      if (requiredRights != null)
      {
        int myrights   = System.app?.user.rights ?? 0;
        bool connected = System.app?.user.connected ?? false;

        // logged on?
        if (!connected)
        {
          // fetch logon template
          var login = System.app?.loginPage;
          if (!S.isNullOrEmpty(login)) template = await Template.fetch(url:login!, refresh: refresh);
          xml = template.document!.rootElement;
        }

        // authorized?
        else if (myrights < requiredRights)
        {
          // fetch not authorized template
          var unauthorized = System.app?.unauthorizedPage;
          if (!S.isNullOrEmpty(unauthorized)) template = await Template.fetch(url: unauthorized!, refresh: refresh);
          xml = template.document!.rootElement;
        }
      }

      // register late scope
      var alias = Xml.attribute(node: xml, tag: "id");
      if (scope != null && alias != null) System.app?.scopeManager.add(scope!, alias: alias);

      // set template name
      templateName = uri.replace(queryParameters: null).toString();
      if (dependency != null) this.dependency = dependency;

      // deserialize from xml
      deserialize(xml);

      // If the model contains any databrokers we fire them before building so we can bind to the data
      // This normally happens in the view initState(), however, since the view builds before the
      // template has been loaded, initState() has already run and we need to do it here.
      model.initialize();
    }
    catch(e)
    {
      String msg = "Error building model from template $url";
      Log().error(msg);
      return Future.error(msg);
    }
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement? xml)
  {
    if (xml == null) return;

    //Log().debug('Deserialize called on framework model => <FML name="$templateName" url="$url"/>');

    // remember xml node
    element = xml;

    // get bindings
    bindables = Binding.getBindingKeys(xml.toXmlString());
    bindables ??= [];

    // stack index
    index = -1;

    // deserialize 
    super.deserialize(xml);

    // properties
    key          = xml.getAttribute('key')                ?? key ?? S.newId();
    dependency   = xml.getAttribute('dependency')         ?? dependency;
    title        = Xml.get(node: xml, tag: 'title')       ?? title;
    version      = Xml.get(node: xml, tag: 'version')     ?? version;
    onstart      = Xml.get(node: xml, tag: 'onstart')     ?? onstart;
    url          = Xml.get(node: xml, tag: 'url')         ?? url;
    orientation  = Xml.get(node: xml, tag: 'orientation') ?? orientation;
    onreturn     = Xml.get(node: xml, tag: 'onreturn')    ?? onreturn;

    // header
    List<HeaderModel> headers = findChildrenOfExactType(HeaderModel).cast<HeaderModel>();
    for (var header in headers) {
      if (header == headers.first)
      {
        this.header = header;
        this.header!.registerListener(this);
      }
      if (children!.contains(header)) children!.remove(header);
    }
    removeChildrenOfExactType(HeaderModel);

    // footer
    List<FooterModel> footers = findChildrenOfExactType(FooterModel).cast<FooterModel>();
    for (var footer in footers) {
      if (footer == footers.first)
      {
        this.footer = footer;
        this.footer!.registerListener(this);
      }
      if (children!.contains(footer)) children!.remove(footer);
    }
    removeChildrenOfExactType(FooterModel);

    // build drawers
    List<XmlElement>? nodes;
    nodes = Xml.getChildElements(node: xml, tag: "DRAWER");
    if (nodes != null && nodes.isNotEmpty) drawer = DrawerModel.fromXmlList(this, nodes);

    // ready
    initialized = true;
  }

  @override
  // framework level dispose can happen asynchronously
  void dispose() async
  {
    Log().debug('Dispose called on framework model => <FML name="$templateName" url="$url"/>');

    disposed = true;

    // dispose header model
    header?.dispose();

    // dispose footer model
    footer?.dispose();

    // dispose drawer model
    drawer?.dispose();

    // dispose of scope
    scope?.dispose();

    // clear event listeners
    manager.listeners.clear();

    // cleanup children
    super.dispose();
  }

  Future<bool> onStart(BuildContext context) async
  {
    await NavigationManager().onPageLoaded();
    return await EventHandler(this).execute(_onstart);
  }

  Future<bool> onPush(Map<String?, String> parameters) async
  {
    // set variables from return parameters
    if ((scope != null)) parameters.forEach((key, value) => scope!.setObservable(key, value));

    // fire OnReturn event
    if (!S.isNullOrEmpty(onreturn)) EventHandler(this).execute(_onreturn);

    return true;
  }

  // get return parameters
  Map<String?, String> onPop() => parameters;

  /// Callback function for when the model changes, used to force a rebuild with setState()
  @override
  onModelChange(WidgetModel model,{String? property, dynamic value})
  {
    try
    {
      Binding? b = Binding.fromString(property);
      if ((b?.property == 'visible') || (b?.property == 'height') || (b?.property == 'minheight') || (b?.property == 'maxheight')) notifyListeners(property, value);
    }
    catch(e)
    {
      Log().exception(e, caller: 'Framework.View');
    }
  }

  void onTitleChange(BuildContext? context)
  {
    // set tab title
    if (index == 0) System().setApplicationTitle(title);

    // update page title
    if (context != null) NavigationManager().setPageTitle(context, title);
  }

  void showTemplate()
  {
    // save bytes to file
    if (element != null)
    {
      var bytes = utf8.encode(element!.toXmlString());
      var uri = URI.parse(templateName);
      if (uri != null) {
        Platform.fileSaveAs(bytes, uri.url);
      } else {
        Platform.fileSaveAs(bytes, "template");
      }
    }
  }

  Future<int?> show({DialogType? type, Image? image, String? title, String? description, Widget? content, List<Widget>? buttons}) async
  {
    if (context == null) return null;
    return DialogManager.show(context!, type: type, image: image, title: title, description: description, content: content, buttons: buttons);
  }

  @override
  Future<bool?> execute(String caller, String propertyOrFunction, List<dynamic> arguments) async
  {
    if (scope == null) return null;
    var function = propertyOrFunction.toLowerCase().trim();
    switch (function)
    {
      // show template
      case "showtemplate":
        showTemplate();
        return true;
    }
    return super.execute(caller, propertyOrFunction, arguments);
  }
  @override
  Widget getView({Key? key}) => getReactiveView(FrameworkView(this));
}

abstract class IDragListener
{
  onDragOpen(DragStartDetails details, String dir);
  onDragEnd(DragEndDetails details, String dir, bool isOpen);
  onDragSheet(DragUpdateDetails details, String dir, bool isOpen);
}
