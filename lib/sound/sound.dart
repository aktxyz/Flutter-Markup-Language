// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class Sound {
  static AudioCache assetPlayer = AudioCache(); // asset caching for mobile only
  static AudioPlayer advancedPlayer = AudioPlayer();

  init() {
    initPlayer();
  }

  void initPlayer() {
    if (kIsWeb) return; // Calls to Platform.isIOS fails on web
    else if (Platform.isIOS)
    {
     // if (assetPlayer.fixedPlayer != null) {
     //   assetPlayer.fixedPlayer.startHeadlessService();
     // }
     // advancedPlayer.startHeadlessService();
    }
  }

//  To add local audio assets for web include the file in:
//  /web/assets/audio
//  then play like so: Sound.playLocal('beep.mp3');
  static playLocal(String localPath, {int? duration}) async { // dir
    await advancedPlayer.play(localPath, isLocal: true);
    if (duration != null && duration > 0)
      Future.delayed(Duration(seconds: duration), () => advancedPlayer.stop());
  }

//  To add local audio assets for mobile include the file in
//  /assets/audio/
//  and then under `assets:` in pubspec.yaml
  static playAsset(String filename, {int? duration}) async { // dir
    AudioPlayer ap = await assetPlayer.play(filename);
    if (duration != null && duration > 0)
      Future.delayed(Duration(seconds: duration), () => ap.stop());
  }

//  To play remote files use a url for the remotePath
  static playRemote(String remotePath, {int? duration}) async { // url
    await advancedPlayer.play(remotePath, isLocal: false);
    if (duration != null && duration > 0)
      Future.delayed(Duration(seconds: duration), () => advancedPlayer.stop());
  }
}