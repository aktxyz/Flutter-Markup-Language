// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/decorated/decorated_widget_model.dart';
import 'package:fml/widgets/widget/widget_model.dart'  ;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:fml/widgets/image/image_view.dart';
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/common_helpers.dart';

class ImageModel extends DecoratedWidgetModel 
{
  //////////
  //* url */
  //////////
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

  //////////////
  //* default */
  //////////////
  StringObservable? _default;
  set defaultvalue (dynamic v)
  {
    if (_default != null)
    {
      _default!.set(v);
    }
    else if (v != null)
    {
      _default = StringObservable(Binding.toKey(id, 'default'), v, scope: scope, listener: onPropertyChange);
    }
  }
  String? get defaultvalue => _default?.get();

  //////////////
  /* rotation */
  //////////////
  DoubleObservable? _rotation;
  set rotation (dynamic v)
  {
    if (_rotation != null)
    {
      _rotation!.set(v);
    }
    else if (v != null)
    {
      _rotation = DoubleObservable(Binding.toKey(id, 'rotation'), v, scope: scope, listener: onPropertyChange);
    }
  }
  double? get rotation => _rotation?.get();

  /////////
  /* fit */
  /////////
  StringObservable? _fit;
  set fit (dynamic v)
  {
    if (_fit != null)
    {
      _fit!.set(v);
    }
    else if (v != null)
    {
      _fit = StringObservable(Binding.toKey(id, 'fit'), v, scope: scope, listener: onPropertyChange);
    }
  }
  String? get fit => _fit?.get();

  ////////////
  /* filter */
  ////////////
  StringObservable? _filter;
  set filter (dynamic v)
  {
    if (_filter != null)
    {
      _filter!.set(v);
    }
    else if (v != null)
    {
      _filter = StringObservable(Binding.toKey(id, 'filter'), v, scope: scope, listener: onPropertyChange);
    }
  }
  String? get filter => _filter?.get();

  ////////////
  /* flip */
  ////////////
  StringObservable? _flip;
  set flip (dynamic v)
  {
    if (_flip != null)
    {
      _flip!.set(v);
    }
    else if (v != null)
    {
      _flip = StringObservable(Binding.toKey(id, 'flip'), v, scope: scope, listener: onPropertyChange);
    }
  }
  String? get flip => _flip?.get();

  // interactive
  BooleanObservable? _interactive;
  set interactive(dynamic v)
  {
    if (_interactive != null)
    {
      _interactive!.set(v);
    }
    else if (v != null)
    {
      _interactive = BooleanObservable(Binding.toKey(id, 'interactive'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get interactive => _interactive?.get() ?? false;

  ImageModel(
    WidgetModel parent,
    String?  id,
   {
    dynamic url,
    dynamic defaultvalue,
    dynamic width,
    dynamic height,
    dynamic rotation,
    dynamic opacity,
    dynamic fit,
    dynamic filter,
    dynamic flip,
    dynamic interactive
   }) : super(parent, id)
  {
    if (width  != null) this.width  = width;
    if (height != null) this.height = height;

    this.rotation     = rotation;
    this.opacity      = opacity;
    this.url          = url;
    this.defaultvalue = defaultvalue;
    this.fit          = fit;
    this.filter       = filter;
    this.flip         = flip;
    this.interactive  = interactive;
  }

  static ImageModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    ImageModel? model;
    try
    {
      model = ImageModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'image.Model');
      model = null;
    }
    return model;
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement xml)
  {

    // deserialize 
    super.deserialize(xml);

    // properties
    url           = Xml.get(node: xml, tag: 'url');
    defaultvalue  = Xml.get(node: xml, tag: 'default');
    rotation      = Xml.get(node: xml, tag: 'rotation');
    opacity       = Xml.get(node: xml, tag: 'opacity');
    fit           = Xml.get(node: xml, tag: 'fit');
    filter        = Xml.get(node: xml, tag: 'filter');
    flip          = Xml.get(node: xml, tag: 'flip');
    interactive   = Xml.get(node: xml, tag: 'interactive');
  }

  @override
  dispose()
  {
    // Log().debug('dispose called on => <$elementName id="$id">');
    super.dispose();
  }

  @override
  Widget getView({Key? key}) => getReactiveView(ImageView(this));
}