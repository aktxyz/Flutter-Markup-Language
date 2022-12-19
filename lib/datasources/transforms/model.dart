// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/widget/widget_model.dart'  ;
import 'package:image/image.dart' as IMAGE;
import 'package:xml/xml.dart';
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/helper_barrel.dart';

enum TransformTypes {calc, distinct, eval, filter, format, pivot, sort}

abstract class IDataTransform
{
  bool? get enabled;
  void apply(List? list);
}

abstract class IImageTransform
{
  bool? get enabled;
  IMAGE.Image? apply(IMAGE.Image? image);
}

class TransformModel extends WidgetModel
{
  // enabled
  BooleanObservable? _enabled;
  set enabled(dynamic v)
  {
    if (_enabled != null)
    {
      _enabled!.set(v);
    }
    else if (v != null)
    {
      _enabled = BooleanObservable(Binding.toKey(id, 'enabled'), v, scope: scope, listener: onPropertyChange);
    }
  }
  bool get enabled => _enabled?.get() ?? true;

  TransformModel(WidgetModel? parent, String? id) : super(parent, id);

  static TransformModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    TransformModel? model;
    try
    {
      model = TransformModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'iframe.Model');
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
    enabled = Xml.get(node: xml, tag: 'enabled');
  }
}
