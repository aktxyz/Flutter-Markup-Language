// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:async';
import 'package:fml/log/manager.dart';
import 'package:fml/navigation/manager.dart';
import 'package:fml/observable/binding.dart';
import 'package:fml/system.dart';
import 'package:uuid/uuid.dart';
import 'package:validators/validators.dart';
import 'package:xml/xml.dart';
import 'package:fml/datasources/http/http.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:fml/hive/form.dart' as DATABASE;
import 'package:fml/helper/helper_barrel.dart';

// platform
import 'package:fml/platform/platform.stub.dart'
if (dart.library.io)   'package:fml/platform/platform.vm.dart'
if (dart.library.html) 'package:fml/platform/platform.web.dart';

class Template
{
  final String? name;
  final XmlDocument? document;

  Template({this.name, this.document});

  static XmlDocument? _fromMemory(String url)
  {
    String? filename = Url.path(Url.toAbsolute(url));
    if (System().templates.containsKey(filename)) return System().templates[filename];
    return null;
  }

  static toMemory(String url, XmlDocument? document)
  {
    String? filename = Url.path(Url.toAbsolute(url));
    if (filename != null) System().templates[filename] = document;
  }

  static Future<String?> _fromDatabase(String key) async
  {
    String? template;
    try
    {
      // lookup from local hive
      DATABASE.Form? form = await DATABASE.Form.find(key);
      if (form != null) template = form.template;
    }
    catch (e)
    {
      Log().exception(e);
      template = null;
    }
    return template;
  }

  static Future<String?> _fromAssetsBundle(String url) async
  {
    String? template;
    try
    {
      // not supported on web
      if (isWeb) throw('Local Files not supported in Browser');

      // get template from asset bundle
      template = await rootBundle.loadString(url.replaceFirst("file://", "assets/"), cache: false);
    }
    catch (e)
    {
      template = null;
    }
    return template;
  }

  static Future<String?> _fromFile(String url) async
  {
    String? template;
    try
    {
      // not supported on web
      if (isWeb)    throw('Local Files not supported in Browser');
      if (isMobile) throw('Local Files not supported in Mobile');

      // get template from file
      Uri? uri = Url.parse(url);
      if (uri != null && uri.filePath != null)
      {
        var file = Platform.getFile(uri.filePath);
        if (file != null) template = await Platform.readFile(url);
      }
    }
    catch (e)
    {
      template = null;
    }
    return template;
  }

  static Future<String?> _fromServer(String url) async
  {
    String? template;
    try
    {
      // get template from remote server
      if (Platform.connected == true)
      {
        // get the template from the cloud
        HttpResponse response = await Http.get(url, refresh: true);
        if (!response.ok) throw '[${response.statusCode}] ${response.statusMessage}';
        template = response.body;
      }
      else
      {
        Log().debug("Unable to fetch template from server. No internet connection");
      }
    }
    catch (e)
    {
      Log().error("Can't find valid template $url on server. Error is $e");
    }
    return template;
  }

  static Future<String?> _fromDisk(String url) async
  {
    String? template;
    try
    {
      String? filename = Url.path(Url.toAbsolute(url));
      if (filename != null)
      {
        bool exists = Platform.fileExists(filename);
        if (exists) template = await Platform.readFile(filename);
      }
    }
    catch (e)
    {
      Log().exception(e);
      template = null;
    }
    return template;
  }

  static Future<bool> _toDisk(String url, String xml) async
  {
    String? filename = Url.path(Url.toAbsolute(url));
    if (filename != null)
    {
      Log().debug('Writing $filename to disk", object: "TEMPLATE"');
      return await Platform.writeFile(filename, xml);
    }
    return false;
  }

  factory Template.fromDocument({String? name, XmlDocument? xml, Map<String, String?>? parameters})
  {
    Template template = Template(name: name, document: xml);
    template = Template.fromTemplate(template: template, parameters: parameters);
    return template;
  }

  factory Template.fromTemplate({required Template template, Map<String, String?>? parameters})
  {
    try
    {
      // Convert Xml Document to Xml String
      String? xml = template.document.toString();

      // Replace Bindings in Xml
      if (parameters != null) xml = Binding.applyMap(xml, parameters, caseSensitive: false);

      // Replace query parameters
      xml = Binding.applyMap(xml, System().app?.queryParameters, caseSensitive: false);

      // Replace config parameters
      xml = Binding.applyMap(xml, System().app?.configParameters, caseSensitive: false);

      // Replace System Uuid
      String s = Binding.toKey("SYSTEM", 'uuid')!;
      while (xml!.contains(s)) xml = xml.replaceFirst(s, Uuid().v4());

      // Convert Xml String to Xml Document
      XmlDocument document = XmlDocument.parse(xml);

      // return the new template
      template = Template(name: template.name, document: document);
    }
    catch (e)
    {
      Log().debug(e.toString());
    }

    return template;
  }

  static Future<XmlDocument?> fetchTemplate({required String url, Map<String, String?>? parameters, bool refresh = false}) async
  {
    Log().debug('Getting template ' + url);

    url = Url.toAbsolute(url);

    String? template;
    bool isFileUrl = url.toLowerCase().trim().startsWith("file://");

    // get template from file
    if (template == null && !isFileUrl)
    {
      // requested template is a form?
      if (isUUID(url)) template = await _fromDatabase(url);

      // get template from server
      if (template == null && (refresh == true || (System().app?.autoRefresh ?? false)))
      {
        // get template
        template = await _fromServer(url);

        // save to local storage
        if (template != null) _toDisk(url, template);
      }

      // get template from memory
      if (template == null)
      {
        XmlDocument? document = _fromMemory(url);
        if (document != null) return document;
      }

      // get template from disk
      if (template == null) template = await _fromDisk(url);

      // get template from database (web)
      if (template == null) template = await _fromDatabase(url);

      // get template from server
      if (template == null)
      {
        // get template
        template = await _fromServer(url);

        // save to local storage
        if (template != null) _toDisk(url, template);
      }
    }

    // local template
    else
    {
      // from assets archive
      if (template == null) template = await _fromAssetsBundle(url);

      // from assets archive
      if (template == null) template = await _fromFile(url);

      // from file
      if (template == null) template = await _fromDisk(url);
    }

    // nothing to process
    if (template == null)
    {
      Log().error("Template $url not found!");
      return null;
    }

    // parse the document
    XmlDocument? document;
    try
    {
      document = XmlDocument.parse(template);
    }
    catch(e)
    {
      Log().error("Error fetching template. Error is $e");
      document = null;
    }

    // process includes
    if (document != null) await _processIncludes(document, parameters);

    // cache in memory after processing include files
    if (document != null) await toMemory(url, document);

    // return the template
    return document;
  }

  static Future<Template> fetch({required String url, Map<String, String?>? parameters, bool? refresh = false}) async
  {
    Log().debug('Building template');

    XmlDocument? document = await fetchTemplate(url: url);
    if (document != null) return Template.fromDocument(name: url, xml: document, parameters: parameters);

    // not found - build error template
    String? xml404 = _buildErrorTemplate('Page Not Found', null, "$url");

    // parse the error template created
    try
    {
      document = XmlDocument.parse(xml404!);
    }
    on  Exception catch(e)
    {
      xml404 = _buildErrorTemplate('Error on Page', '$url', e.toString());
      document = Xml.tryParse(xml404);
    }

    // return the error template
    return Template.
    fromDocument(name: url, xml: document, parameters: parameters);
  }

  static Future<bool> _processIncludes(XmlDocument document, Map<String, String?>? parameters) async
  {
    Iterable<XmlElement> includes = document.findAllElements("INCLUDE", namespace: "*");
    for (XmlElement element in includes)
    {
      // exclude?
      bool exclude = WidgetModel.excludeFromTemplate(element, System().scope);
      if (!exclude)
      {
        // get template segment
        String url = Binding.applyMap(Xml.get(node: element, tag: 'url'), parameters, caseSensitive: false)!;

        // fetch the include template
        Uri? uri = Uri.tryParse(url);
        if (uri != null)
        {
          // parameters
          Map<String, String> parameters = Map<String, String>();
          parameters.addAll(uri.queryParameters);

          // fetch the template
          var template = await Template.fetchTemplate(url: url, parameters: parameters);

          // inject include segment into document
          if (template != null)
          {
            int position = element.parent!.children.indexOf(element);
            try
            {
              // include must always be wrapped in a parent that is ignored, often <FML>
              List<XmlElement> nodes = [];
              XmlElement? include = template.document!.rootElement;
              for (dynamic node in include.children)
                if (node is XmlElement) nodes.add(node.copy());
              element.parent!.children.insertAll(position, nodes);
            }
            catch (e)
            {
              Log().debug("Error parsing include file $url. Error is $e");
            }
          }
        }
      }

      ///////////////////////////////
      /* Remove Node from Document */
      ///////////////////////////////
      element.parent!.children.remove(element);
    }
    return true;
  }

  static String? _buildErrorTemplate(String err1, [String? err2, String? err3])
  {
    String backbutton = NavigationManager().pages.length > 1 ? '<BUTTON onclick="back()" value="go back" type="text" color="#35363A" />' : '';

    String xml = '''
    <ERROR linkable="true">
      <BOX width="100%" height="100%" color1="white" color2="grey" start="topleft" end="bottomright" center="true">
        <ICON icon="error_outline" size="128" color="red" />
        <PAD top="30" />
        <CENTER>
        <TEXT id="e1" size="26" color="#35363A" bold="true">
        <VALUE><![CDATA[$err1]]></VALUE>
        </TEXT> 
        </CENTER>
        <PAD top="10" visible="=!noe({e2})" />
        <TEXT id="e2" visible="=!noe({e2})" size="16" color="red">
        <VALUE><![CDATA[$err2]]></VALUE>
        </TEXT> 
        <PAD top="10" visible="=!noe({e3})" />
        <TEXT id="e3" visible="=!noe({e3})" size="16" color="#35363A">
        <VALUE><![CDATA[$err3]]></VALUE>
        </TEXT> 
        <PAD top="30" />
        $backbutton
      </BOX>
    </ERROR>
    ''';
    return xml;
  }
}
