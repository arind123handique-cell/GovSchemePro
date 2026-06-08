import 'package:flutter/material.dart';

import 'local_image_io.dart'
    if (dart.library.js_interop) 'local_image_web.dart' as impl;

/// Displays a locally stored image cross-platform.
///
/// On native platforms it reads the file from disk; on web it loads the
/// object URL produced by the image picker.
class LocalImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const LocalImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) =>
      impl.buildLocalImage(path, width: width, height: height, fit: fit);
}
