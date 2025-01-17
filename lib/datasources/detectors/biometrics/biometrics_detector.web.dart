// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'biometrics_detector.dart';

import 'package:fml/datasources/detectors/image/detectable_image.stub.dart'
if (dart.library.io)   'package:fml/datasources/detectors/image/detectable_image.mobile.dart'
if (dart.library.html) 'package:fml/datasources/detectors/image/detectable_image.web.dart';

BiometricsDetector getDetector() => BiometricsDetector();

class BiometricsDetector implements IBiometricsDetector
{
  static final BiometricsDetector _singleton = BiometricsDetector._initialize();

  BiometricsDetector._initialize();

  factory BiometricsDetector()
  {
    return _singleton;
  }

  @override
  Future<Payload?> detect(DetectableImage image) async
  {
    // not implemented
    return null;
  }
}