/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatview_utils/chatview_utils.dart';
import 'package:flutter/material.dart';

class ProfileImageWidget extends StatelessWidget {
  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.userName,
    this.userId,
    this.fallbackBackgroundColor,
    this.defaultAvatarImage = Constants.profileImage,
    this.circleRadius,
    this.assetImageErrorBuilder,
    this.networkImageErrorBuilder,
    this.imageType = ImageType.network,
    required this.networkImageProgressIndicatorBuilder,
  });

  /// chattr p20: app-injectable resolver for the initials-circle background so
  /// the host app can derive ONE stable identity colour per user across every
  /// surface (message circles, reaction pills, app bar, reaction sheet).
  /// Called with whatever the call site knows (id and/or name); return null to
  /// keep the built-in name-hash colour. Set once at app startup.
  static Color? Function(String? userId, String? userName)?
      fallbackColorResolver;

  /// chattr p21: app-injectable resolver for the initials *foreground*. Set it
  /// alongside [fallbackColorResolver] so the host app owns ONE contrast rule
  /// for every avatar — in-package circles and app-side ones alike. Return null
  /// to keep the built-in rule below.
  static Color? Function(Color background)? fallbackForegroundResolver;

  /// chattr p25: app-injectable cache key for network avatars.
  ///
  /// [CachedNetworkImage] keys its disk cache on the URL. That is wrong the
  /// moment the URL is a SIGNED one: every refreshed signature looks like a
  /// new picture, so the same avatar is downloaded again and again and its
  /// files accumulate without bound. Return a stable identity for the URL
  /// (the storage path, say) — or null to keep keying on the URL. Set once at
  /// app startup.
  static String? Function(String url)? cacheKeyResolver;

  /// Allow user to set radius of circle avatar.
  final double? circleRadius;

  /// Allow user to pass image url of user's profile picture.
  final String? imageUrl;

  /// Optional display name used to render an initials-circle fallback when no
  /// [imageUrl] resolves (chattr fork p12). When null/empty the widget keeps the
  /// original empty behaviour (a zero-size box), so callers that don't pass a
  /// name are unaffected.
  final String? userName;

  /// chattr p20: the user's id, forwarded to [fallbackColorResolver] where the
  /// call site knows it. Purely additive — no behaviour change when unset.
  final String? userId;

  /// chattr p20: explicit background for the initials fallback; wins over
  /// [fallbackColorResolver] and the built-in name-hash colour.
  final Color? fallbackBackgroundColor;

  /// Flag to check whether image is network or asset
  final ImageType? imageType;

  /// Field to set default avatar image if profile image link not provided
  final String defaultAvatarImage;

  /// Error builder to build error widget for asset image
  final AssetImageErrorBuilder? assetImageErrorBuilder;

  /// Error builder to build error widget for network image
  final NetworkImageErrorBuilder? networkImageErrorBuilder;

  /// Progress indicator builder for network image
  final NetworkImageProgressIndicatorBuilder?
      networkImageProgressIndicatorBuilder;

  @override
  Widget build(BuildContext context) {
    final radius = (circleRadius ?? 20) * 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(circleRadius ?? 20),
      child: switch (imageType) {
        ImageType.asset when (imageUrl?.isNotEmpty ?? false) => Image.asset(
            imageUrl!,
            height: radius,
            width: radius,
            fit: BoxFit.cover,
            errorBuilder: assetImageErrorBuilder ?? _errorWidget,
          ),
        ImageType.network when (imageUrl?.isNotEmpty ?? false) =>
          CachedNetworkImage(
            imageUrl: imageUrl ?? defaultAvatarImage,
            // chattr p25: a signed URL changes on every refresh; without a
            // stable key the disk cache would grow one copy per signature.
            cacheKey: cacheKeyResolver?.call(imageUrl ?? defaultAvatarImage),
            height: radius,
            width: radius,
            fit: BoxFit.cover,
            progressIndicatorBuilder:
                networkImageProgressIndicatorBuilder == null
                    ? null
                    : (context, url, progress) =>
                        networkImageProgressIndicatorBuilder!.call(
                          context,
                          url,
                          CacheNetworkImageDownloadProgress(
                            progress.originalUrl,
                            progress.totalSize,
                            progress.downloaded,
                          ),
                        ),
            errorWidget: networkImageErrorBuilder ?? _networkImageErrorWidget,
          ),
        ImageType.base64 when (imageUrl?.isNotEmpty ?? false) => Image.memory(
            base64Decode(imageUrl!),
            height: radius,
            width: radius,
            fit: BoxFit.cover,
            errorBuilder: assetImageErrorBuilder ?? _errorWidget,
          ),
        _ => _fallbackAvatar(radius),
      },
    );
  }

  /// Fallback when no image resolves. With a [userName] this renders a filled
  /// initials circle (deterministic colour per name) so a picture-less user
  /// keeps a stable avatar slot instead of collapsing to 0px (chattr fork p12).
  /// Without a name it preserves the historical empty box.
  Widget _fallbackAvatar(double radius) {
    final name = userName?.trim() ?? '';
    if (name.isEmpty) return const SizedBox.shrink();
    final initials = _initials(name);
    // chattr p20: explicit colour > app resolver > legacy name-hash. The text
    // colour follows the background's luminance so injected light colours stay
    // readable (the legacy path keeps its hardcoded white).
    final bg = fallbackBackgroundColor ??
        fallbackColorResolver?.call(userId, name) ??
        _colorFor(name);
    final fg = fallbackForegroundResolver?.call(bg) ?? _foregroundOn(bg);
    return Container(
      height: radius,
      width: radius,
      alignment: Alignment.center,
      color: bg,
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.4,
        ),
      ),
    );
  }

  /// chattr p21: the maximally-contrasting foreground for [background]. Picks
  /// whichever of black/white yields the higher WCAG contrast ratio — the
  /// crossover sits at relative luminance ≈0.179, NOT 0.5. The previous `>0.5`
  /// rule put white on mid-luminance hues (yellow/green), where it drops to
  /// ~1.9:1 and the initial becomes unreadable.
  static Color _foregroundOn(Color background) {
    final lum = background.computeLuminance();
    final contrastWithWhite = 1.05 / (lum + 0.05);
    final contrastWithBlack = (lum + 0.05) / 0.05;
    return contrastWithWhite >= contrastWithBlack ? Colors.white : Colors.black;
  }

  static String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Deterministic background colour derived from the name, so a given user
  /// always gets the same circle. Uses Material primaries for a pleasant spread.
  static Color _colorFor(String name) {
    var hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final palette = Colors.primaries;
    return palette[hash % palette.length].shade400;
  }

  Widget _networkImageErrorWidget(
    BuildContext context,
    String url,
    Object error,
  ) {
    return const Center(
      child: Icon(
        Icons.error_outline,
        size: 18,
      ),
    );
  }

  Widget _errorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const Center(
      child: Icon(
        Icons.error_outline,
        size: 18,
      ),
    );
  }
}
