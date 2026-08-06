import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({super.key, this.photoUrl, required this.initials, this.radius = 24});

  final String? photoUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.cream,
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cream,
      backgroundImage: CachedNetworkImageProvider(photoUrl!),
    );
  }
}
