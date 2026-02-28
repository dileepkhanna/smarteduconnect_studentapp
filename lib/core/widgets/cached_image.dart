// lib/core/widgets/cached_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.size,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.showPlaceholderWhenEmpty = true,
  });

  /// Network image url. If null/empty, placeholder will be shown.
  final String? url;

  /// If [size] is provided, it overrides [width]/[height].
  final double? width;
  final double? height;
  final double? size;

  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Custom placeholder widget (shown while loading and when url is empty).
  final Widget? placeholder;

  /// Custom error widget (shown when image fails to load).
  final Widget? errorWidget;

  final Color? backgroundColor;

  /// If true, shows placeholder when [url] is null/empty.
  final bool showPlaceholderWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final double? w = size ?? width;
    final double? h = size ?? height;

    final Widget defaultPlaceholder = Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black12,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Icon(
        Icons.image_rounded,
        size: (size != null ? (size! * 0.45) : 22),
        color: Colors.black38,
      ),
    );

    Widget wrap(Widget child) {
      Widget out = child;

      // Ensure background fills even if child doesn't paint full size
      out = Container(
        width: w,
        height: h,
        color: backgroundColor ?? Colors.transparent,
        child: out,
      );

      if (borderRadius != null) {
        out = ClipRRect(borderRadius: borderRadius!, child: out);
      }
      return out;
    }

    final String? u = url?.trim();
    final bool hasUrl = u != null && u.isNotEmpty;

    if (!hasUrl) {
      if (!showPlaceholderWhenEmpty) {
        return const SizedBox.shrink();
      }
      return wrap(placeholder ?? defaultPlaceholder);
    }

    final Widget ph = placeholder ?? defaultPlaceholder;
    final Widget err = errorWidget ?? ph;

    return CachedNetworkImage(
      imageUrl: u!,
      width: w,
      height: h,
      fit: fit,
      placeholder: (_, __) => wrap(ph),
      errorWidget: (_, __, ___) => wrap(err),
    );
  }
}
