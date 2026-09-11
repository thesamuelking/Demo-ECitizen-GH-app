import 'dart:convert';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  static final Map<String, ImageProvider> _imageCache = {};
  final String? photo;
  final double size;
  final double iconSize;

  const UserAvatar({
    super.key,
    required this.photo,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (photo != null && photo!.startsWith('data:image/')) {
      final comma = photo!.indexOf(',');
      if (comma > 0) {
        image = _imageCache[photo!];
        if (image == null) {
          try {
            image = MemoryImage(base64Decode(photo!.substring(comma + 1)));
            _imageCache[photo!] = image;
          } on FormatException {
            image = null;
          }
        }
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image == null
          ? Center(child: Text('🇬🇭', style: TextStyle(fontSize: iconSize)))
          : null,
    );
  }
}