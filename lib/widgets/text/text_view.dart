// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:fml/system.dart';
import 'package:fml/widgets/widget/widget_model.dart' ;
import 'package:fml/widgets/text/text_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fml/phrase.dart';

class TextView extends StatefulWidget
{
  final TextModel model;
  TextView(this.model) : super(key: ObjectKey(model));

  @override
  _TextViewState createState() => _TextViewState();
}

class _TextViewState extends State<TextView> implements IModelListener {

  @override
  void initState() {
    super.initState();

    
    widget.model.registerListener(this);

    // If the model contains any databrokers we fire them before building so we can bind to the data
    widget.model.initialize();
  }

  @override
  void didUpdateWidget(TextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (
        (oldWidget.model != widget.model)) {
      oldWidget.model.removeListener(this);
      widget.model.registerListener(this);
    }

  }

  @override
  void dispose() {
    widget.model.removeListener(this);

    super.dispose();
  }

  /// Callback to fire the [_TextViewState.build] when the [TextModel] changes
  onModelChange(WidgetModel model, {String? property, dynamic value}) {
    if (this.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context)
  {
    // Check if widget is visible before wasting resources on building it
    if (!widget.model.visible) return Offstage();

    String? label = widget.model.value;
    String? style = widget.model.style;
    double? size = widget.model.size;
    Color? color = widget.model.color;
    String? decoration = widget.model.decoration;
    bool bold = widget.model.bold ?? false;
    bool italic = widget.model.italic ?? false;
    String overflow = widget.model.overflow;
    String halign = widget.model.halign;
    String decorationstyle = widget.model.decorationstyle;
    double? wordSpace = widget.model.wordspace;
    double? letterSpace = widget.model.letterspace;
    double? lineSpace = widget.model.lineheight;

    TextTheme textTheme = Theme
        .of(context)
        .textTheme;
    TextStyle? textStyle = textTheme.bodyText2;
    TextOverflow textOverflow = TextOverflow.ellipsis;
    TextAlign textAlign = TextAlign.left;
    TextDecoration textDecoration = TextDecoration.none;
    TextDecorationStyle textDecoStyle = TextDecorationStyle.solid;

    switch (overflow.toLowerCase()) {
      case "wrap":
        textOverflow = TextOverflow.visible;
        break;
      case "ellipses":
        textOverflow = TextOverflow.ellipsis;
        break;
      case "fade":
        textOverflow = TextOverflow.fade;
        break;
      case "clip":
        textOverflow = TextOverflow.clip;
        break;
      default:
        textOverflow = TextOverflow.visible;
        break;
    }

    switch (halign.toLowerCase()) {
      case "start":
      case "left":
        textAlign = TextAlign.left;
        break;
      case "end":
      case "right":
        textAlign = TextAlign.right;
        break;
      case "center":
        textAlign = TextAlign.center;
        break;
      case "justify":
        textAlign = TextAlign.justify;
        break;
      default:
        textAlign = TextAlign.left;
        break;
    }


    switch (decoration?.toLowerCase()) {
      case "underline":
        textDecoration = TextDecoration.underline;
        break;
      case "strikethrough":
        textDecoration = TextDecoration.lineThrough;
        break;
      case "overline":
        textDecoration = TextDecoration.overline;
        break;
      default:
        textDecoration = TextDecoration.none;
        break;
    }

    switch (decorationstyle.toLowerCase()) {
      case "dashed":
        textDecoStyle = TextDecorationStyle.dashed;
        break;
      case "dotted":
        textDecoStyle = TextDecorationStyle.dotted;
        break;
      case "double":
        textDecoStyle = TextDecorationStyle.double;
        break;
      case "wavy":
        textDecoStyle = TextDecorationStyle.wavy;
        break;
      default:
        textDecoStyle = TextDecorationStyle.solid;
        break;
    }


    switch (style?.toLowerCase()) {
      case "h1":
      case "headline1":
        textStyle = textTheme.headline1;
        break;
      case "h2":
      case "headline2":
        textStyle = textTheme.headline2;
        break;
      case "h3":
      case "headline3":
        textStyle = textTheme.headline3;
        break;
      case "h4":
      case "headline4":
        textStyle = textTheme.headline4;
        break;
      case "h5":
      case "headline5":
        textStyle = textTheme.headline5;
        break;
      case "h6":
      case "headline6":
        textStyle = textTheme.headline6;
        break;
      case "s1":
      case "sub1":
      case "subtitle1":
        textStyle = textTheme.subtitle1;
        break;
      case "s2":
      case "sub2":
      case "subtitle2":
        textStyle = textTheme.subtitle2;
        break;
      case "b1":
      case "body1":
      case "bodytext1":
        textStyle = textTheme.bodyText1;
        break;
      case "b2":
      case "body2":
      case "bodytext2":
        textStyle = textTheme.bodyText2;
        break;
      case "caption":
        textStyle = textTheme.caption;
        break;
      case "button":
        textStyle = textTheme.button;
        break;
      case "overline":
        textStyle = textTheme.overline;
        break;
      default:
        textStyle = textTheme.bodyText2;
        break;
    }
    var textShadow = widget.model.elevation != 0
        ? [
      Shadow(
          color: widget.model.shadowcolor ?? Theme
              .of(context)
              .colorScheme
              .outline
              .withOpacity(0.4),
          blurRadius: widget.model.elevation,
          offset: Offset(
              widget.model.shadowx!,
              widget.model
                  .shadowy!)),
    ]
        : null;


    Color? fontColor = color;
    List<InlineSpan> textSpans = [];
    //**bold** *italic* ***bold+italic***  _underline_  __strikethrough__  ___overline___ ^^subscript^^ ^superscript^

    if (widget.model.markupTextValues.isNotEmpty && !widget.model.raw) {
      widget.model.markupTextValues.forEach((element) {
        InlineSpan textSpan;
        FontWeight? weight;
        FontStyle? style;
        String? script;
        TextDecoration? deco;
        Color? codeBlockBG;
        String? codeBlockFont;

        element.styles.forEach((element) {
          switch (element) {
            case "underline":
              deco = TextDecoration.underline;
              break;
            case "strikethrough":
              deco = TextDecoration.lineThrough;
              break;
            case "overline":
              deco = TextDecoration.overline;
              break;
            case "bold":
              weight = FontWeight.bold;
              break;
            case "italic":
              style = FontStyle.italic;
              break;
            case "subscript":
              script = "sub";
              break;
            case "superscript":
              script = "sup";
              break;
            case "code":
              codeBlockBG = Theme.of(context).colorScheme.surfaceVariant;
              codeBlockFont = 'Cutive Mono';
              weight = FontWeight.w600;
              break;
            default:
              codeBlockBG = Theme.of(context).colorScheme.surfaceVariant;
              codeBlockFont = null;
              weight = FontWeight.normal;
              style = FontStyle.normal;
              deco = TextDecoration.none;
              script = "normal";
              break;
          }
        });

        String text = element.text.replaceAll('\\n', '\n').replaceAll('\\t',
            '\t\t\t\t');

        if (widget.model.addWhitespace) text = ' ' + text;

        //4 ts here as dart interprets the tab character as a single space.

        if (script == "sub") {
          WidgetSpan widgetSpan = WidgetSpan(child: Transform.translate(
            offset: const Offset(2, 4),
            child: Text(text, textScaleFactor: 0.7,
              style: TextStyle(
                  wordSpacing: wordSpace,
                  letterSpacing: letterSpace,
                  height: lineSpace,
                  shadows: textShadow,
                  fontWeight: weight,
                  fontStyle: style,
                  decoration: deco,
                  decorationStyle: textDecoStyle,
                  decorationColor: widget.model.decorationcolor,
                  decorationThickness: widget.model.decorationweight),),),);
          textSpans.add(widgetSpan);
        } else if (script == "sup") {
          WidgetSpan widgetSpan = WidgetSpan(child: Transform.translate(
            offset: const Offset(2, -4),
            child: Text(text, textScaleFactor: 0.7,
              style: TextStyle(
                  wordSpacing: wordSpace,
                  letterSpacing: letterSpace,
                  height: lineSpace,
                  shadows: textShadow,
                  fontWeight: weight,
                  fontStyle: style,
                  decoration: deco,
                  decorationStyle: textDecoStyle,
                  decorationColor: widget.model.decorationcolor,
                  decorationThickness: widget.model.decorationweight),),),);
          textSpans.add(widgetSpan);
        }
        else {
          textSpan = TextSpan(text: text,
              style: GoogleFonts.getFont(codeBlockFont ?? widget.model.font ?? System().font,
                  backgroundColor: codeBlockBG,
                  wordSpacing: wordSpace,
                  letterSpacing: letterSpace,
                  height: lineSpace,
                  shadows: textShadow,
                  fontWeight: weight,
                  fontStyle: style,
                  decoration: deco,
                  decorationStyle: textDecoStyle,
                  decorationColor: widget.model.decorationcolor,
                  decorationThickness: widget.model.decorationweight)
            // style: TextStyle(
            //   wordSpacing: wordSpace,
            //   letterSpacing: letterSpace,
            //   height: lineSpace,
            //   shadows: textShadow,
            //   fontWeight: weight,
            //   fontStyle: style,
            //   decoration: deco,
            //   decorationStyle: textDecoStyle,
            //   decorationColor: widget.model.decorationcolor,
            //   decorationThickness: widget.model.decorationweight
            // ),
          );
          textSpans.add(textSpan);
        }
      });
    }

    if(widget.model.spanRequestBuild) return RichText(
        text: TextSpan(children: textSpans, style: TextStyle(
            fontSize: size ?? textStyle!.fontSize,
            color: fontColor ?? Theme
                .of(context)
                .colorScheme
                .onBackground,
            fontWeight: bold == true ? FontWeight.bold : textStyle!
                .fontWeight,
            fontStyle: italic == true ? FontStyle.italic : textStyle!
                .fontStyle,
            decoration: textDecoration)),
        overflow: textOverflow,
        textAlign: textAlign);



    Widget view;



    if (widget.model.raw) {
      view = SizedBox( //SizedBox is used to make the text fit the size of the widget.
          width: widget.model.width,
          child: Text(widget.model.value ?? '', style: GoogleFonts.getFont(
              widget.model.font ?? System().font,
              fontSize: size ?? textStyle!.fontSize,
              wordSpacing: wordSpace,
              letterSpacing: letterSpace,
              height: lineSpace,
              shadows: textShadow,
              fontWeight: widget.model.bold ?? false ? FontWeight.bold : FontWeight
                  .normal,
              fontStyle: widget.model.italic ?? false ? FontStyle.italic : FontStyle
                  .normal,
              decoration: textDecoration,
              decorationStyle: textDecoStyle,
              decorationColor: widget.model.decorationcolor,
              decorationThickness: widget.model.decorationweight)));
    } else {
      view = SizedBox(
          width: widget.model.width,
          child: RichText(
              text: TextSpan(children: textSpans, style: TextStyle(
                  fontSize: size ?? textStyle!.fontSize,
                  color: fontColor ?? Theme
                      .of(context)
                      .colorScheme
                      .onBackground,
                  fontWeight: bold == true ? FontWeight.bold : textStyle!
                      .fontWeight,
                  fontStyle: italic == true ? FontStyle.italic : textStyle!
                      .fontStyle,
                  decoration: textDecoration)),
              overflow: textOverflow,
              textAlign: textAlign));
    }

    //////////////////
    /* Constrained? */
    //////////////////
    if (widget.model.constrained) {
      Map<String, double?> constraints = widget.model.constraints;
      view = ConstrainedBox(
          child: view,
          constraints: BoxConstraints(
              minHeight: constraints['minheight']!,
              maxHeight: constraints['maxheight']!,
              minWidth: constraints['minwidth']!,
              maxWidth: constraints['maxwidth']!));
    }


    view = GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(phrase.copiedToClipboard),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                elevation: 5));
      }, child: view,);

    return view;
  }
  }