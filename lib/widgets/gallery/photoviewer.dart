// © COPYRIGHT 2022 APPDADDY SOFTWARE SOLUTIONS INC. ALL RIGHTS RESERVED.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:fml/helper/helper_barrel.dart';

class GalleryScreen extends StatefulWidget
{
  final String file;
  GalleryScreen(this.file);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
{
  @override
  void initState()
  {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(body: GalleryWidget(widget.file));
  }
}

class GalleryWidget extends StatefulWidget
{
  final String file;

  GalleryWidget(this.file);

  @override
  State createState() => GalleryWidgetState();
}

class GalleryWidgetState extends State<GalleryWidget>
{
  PageController? pager;
  int currentIndex = 0;

  @override
  Widget build(BuildContext context)
  {
    bool networkImage = false;
    String file = widget.file;

    //////////
    /* Uri? */
    //////////
    if (file.trim().startsWith("data:"))
    {
      UriData uri = UriData.parse(file);
      file = uri.contentText;
    }

    if (file.trim().startsWith('/')) {
      file = Url.toAbsolute(file.trim());
      networkImage = true;
    }
    else if (file.trim().startsWith('http://') || file.trim().startsWith('https://'))
      networkImage = true;

    ImageProvider imageProvider = (networkImage == true
      ? NetworkImage(file)
      : MemoryImage(Base64Codec().decode(file))) as ImageProvider<Object>;

    Widget view = PhotoView(
        imageProvider: imageProvider,
        // loadingBuilder: (context, progress) => Center(
        //   child: Container(
        //     width: 20.0,
        //     height: 20.0,
        //     child: Busy(),
        //   ),
        // ),
        backgroundDecoration: BoxDecoration(color: Theme.of(context).colorScheme.shadow),
        gaplessPlayback: false,
        customSize: MediaQuery.of(context).size,
        enableRotation: true,
        controller:  PhotoViewController(),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 1.8,
        initialScale: PhotoViewComputedScale.contained,
        basePosition: Alignment.center,
    );

    return view;
  }


}