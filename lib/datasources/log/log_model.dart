// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/data/data.dart';
import 'package:fml/datasources/datasource_interface.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/widget/widget_model.dart';
import 'package:fml/datasources/base/model.dart';
import 'package:xml/xml.dart';
import 'package:fml/helper/common_helpers.dart';

class LogModel extends DataSourceModel implements IDataSource
{
  LogModel(WidgetModel parent, String? id) : super(parent, id);

  @override
  bool get autoexecute => super.autoexecute ?? true;

  static LogModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    LogModel? model;
    try
    {
      model = LogModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'log_model');
      model = null;
    }
    return model;
  }

  @override
  Future<bool> start({bool refresh = false, String? key}) async
  {
    if (enabled == false) return false;
    busy = true;
    Data data = Log().data;
    busy = false;
    return await super.onSuccess(data);
  }

  @override
  Future<bool?> execute(String caller, String propertyOrFunction, List<dynamic> arguments) async
  {
    var function = propertyOrFunction.toLowerCase().trim();
    switch (function)
    {
      case "write":
        String? message = S.toStr(S.item(arguments, 0));
        if (message != null) Log().info(message, caller: id);
        return true;

      case "export":
        String format  =  S.toStr(S.item(arguments, 0))?.toLowerCase() ?? "html";
        bool   history =  S.toBool(S.item(arguments, 1)) ?? false;
        Log().export(format: format, withHistory: history);
        return true;

      case "clear":
        Log().clear();
        return true;

      case 'start':
      case 'fire':
        super.onSuccess(Log().data);
        return true;
    }
    return super.execute(caller, propertyOrFunction, arguments);
  }

  /// Deserializes the FML template elements, attributes and children
  @override
  void deserialize(XmlElement xml)
  {
    super.deserialize(xml);
  }
}