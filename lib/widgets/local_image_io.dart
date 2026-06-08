import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final File file = File(path);
  if (!file.existsSync()) return _placeholder(width, height);
  return Image.file(
    file,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
        _placeholder(width, height),
  );
}

Widget _placeholder(double? width, double? height) => Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
    );
