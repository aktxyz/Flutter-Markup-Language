// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'stream.mobile.dart'
if (dart.library.io)   'stream.mobile.dart'
if (dart.library.html) 'stream.web.dart';

abstract class StreamView
{
  factory StreamView(model) => getView(model)!;
}