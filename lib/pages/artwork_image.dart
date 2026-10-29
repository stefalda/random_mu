import 'dart:io' as io;

import 'package:flutter/material.dart';

/// Image provider for an artwork URI: a file provider for downloaded artwork,
/// a network provider for everything else.
ImageProvider? artworkImageProvider(Uri? uri) {
  if (uri == null) return null;
  if (uri.isScheme('file')) return FileImage(io.File(uri.toFilePath()));
  return NetworkImage(uri.toString());
}

/// Shows album artwork from either the network or a downloaded file.
///
/// Downloaded songs carry a `file://` artwork URI (see `resolveArtUri`), while
/// streamed songs keep the server URL: `Image.network` cannot load `file://`,
/// so the widget picks the right loader.
class ArtworkImage extends StatelessWidget {
  final Uri? uri;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const ArtworkImage({
    super.key,
    required this.uri,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final provider = artworkImageProvider(uri);
    if (provider == null) return fallback ?? const SizedBox.shrink();

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
