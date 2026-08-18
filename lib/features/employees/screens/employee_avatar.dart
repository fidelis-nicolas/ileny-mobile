import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';

/// Circular avatar: the person's photo, or their initials when there isn't one.
///
/// **Photos are not public URLs.** `/files/**` resolves the path back to the
/// record that owns it and checks that record's tenant against the caller's, so
/// it needs the bearer token like any other endpoint. `CachedNetworkImage` does
/// not go through dio and so gets no `Authorization` header of its own — it has
/// to be handed one, or every avatar silently 401s and falls back to initials,
/// which reads as "the upload didn't work" rather than "the fetch didn't".
///
/// The token is read synchronously from [TokenStorage]'s in-memory copy at build
/// time. If it has expired the image 401s and shows initials until the next
/// rebuild after dio refreshes — an avatar is not worth duplicating the
/// refresh-and-retry dance for, and any API call in the session repairs it.
class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({super.key, this.photoUrl, required this.initials, this.radius = 24});

  final String? photoUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return _initialsAvatar(context);
    }

    final token = context.read<TokenStorage>().accessToken;

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.palette.surfaceAlt,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          httpHeaders: token == null ? const {} : {'Authorization': 'Bearer $token'},
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Initials stay visible while loading and if the fetch fails, so a
          // slow or broken image degrades to what was shown before rather than
          // to a broken-image glyph.
          placeholder: (context, url) => _initialsLabel(context),
          errorWidget: (context, url, error) => _initialsLabel(context),
        ),
      ),
    );
  }

  Widget _initialsAvatar(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.palette.primarySoft,
      child: _initialsLabel(context),
    );
  }

  Widget _initialsLabel(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: context.palette.primary,
          fontWeight: FontWeight.w700,
          // Scale with the avatar: the same fixed size looked lost at radius 32
          // on the profile screen and clipped at radius 14 in the app bar.
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
