import 'package:flutter/material.dart';

Widget buildLocalImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (path.isEmpty) return _placeholder(width, height);
  return Image.network(
    path,
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
      child: const Icon(Icons.image_outlined, color: Colors.black38),
    );
