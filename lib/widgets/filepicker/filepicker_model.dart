// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/data/data.dart';
import 'package:fml/datasources/file/model.dart';
import 'package:fml/datasources/datasource_interface.dart';
import 'package:fml/log/manager.dart';
import 'package:fml/widgets/widget/widget_model.dart'  ;
import 'package:xml/xml.dart';
import 'package:fml/widgets/filepicker/filepicker_view.dart' as file_picker;
import 'package:fml/datasources/file/file.dart';
import 'package:fml/event/handler.dart'           ;
import 'package:fml/observable/observable_barrel.dart';
import 'package:fml/helper/common_helpers.dart';

class FilepickerModel extends FileModel implements IDataSource
{
  File? file;
  String? allow;

  // onstart - fired when the picker is launched
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

  // ondismissed - fired when the picker is dismissed
  StringObservable? _ondismissed;
  set ondismissed (dynamic v)
  {
    if (_ondismissed != null)
    {
      _ondismissed!.set(v);
    }
    else if (v != null)
    {
      _ondismissed = StringObservable(Binding.toKey(id, 'ondismissed'), v, scope: scope, lazyEval: true);
    }
  }
  String? get ondismissed
  {
    return _ondismissed?.get();
  }
  
  FilepickerModel(WidgetModel parent, String? id) : super(parent, id);

  static FilepickerModel? fromXml(WidgetModel parent, XmlElement xml)
  {
    FilepickerModel? model;
    try
    {
      model = FilepickerModel(parent, Xml.get(node: xml, tag: 'id'));
      model.deserialize(xml);
    }
    catch(e)
    {
      Log().exception(e,  caller: 'filepicker_model');
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
    allow   = Xml.get(node: xml, tag: 'allow');
    onstart = Xml.get(node: xml, tag: 'onstart');
    ondismissed = Xml.get(node: xml, tag: 'ondismissed');
  }
  
  @override
  Future<bool> start({bool refresh = false, String? key}) async
  {
    bool ok = true;

    try
    {
      file_picker.FilePicker filepicker = file_picker.FilePicker(allow);

      // fire on start
      if (onstart != null)
      {
        var handler = EventHandler(this);
        ok = await handler.execute(_onstart);
        if (ok == false) return ok;
      }

      File? file = await filepicker.launchPicker(detectors);
      if (file != null)
      {
        if ((this.file != null) && (scope != null) && (scope!.files.containsValue(this.file))) scope!.files.remove(this.file);
        this.file = file;
        await onFile(file);
      }

      // fire on dismissed
      else if (ondismissed != null)
      {
        var handler = EventHandler(this);
       ok = await handler.execute(_ondismissed);
        if (ok == false) return ok;
      }
    }
    catch(e)
    {
      ok = await onFail(Data(), code: 500, message: e.toString());
    }

    return ok;
  }
  @override
  Future<bool?> execute(String caller, String propertyOrFunction, List<dynamic> arguments) async
  {
    /// setter
    if (scope == null) return null;
    var function = propertyOrFunction.toLowerCase().trim();
    
    switch (function)
    {
      case "launch" : return await start();
      case "start"  : return await start();
    }
    return super.execute(caller, propertyOrFunction, arguments);
  }
}
