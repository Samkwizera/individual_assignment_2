import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../utils/constants.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final double? distanceKm;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                kCategoryIcons[listing.category] ?? Icons.place_rounded,
                color: AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        listing.reviewCount > 0
                            ? listing.rating.toStringAsFixed(1)
                            : 'New',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (listing.reviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${listing.reviewCount})',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.textSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.shortAddress,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (distanceKm != null)
                  Text(
                    distanceKm! < 1
                        ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                        : '${distanceKm!.toStringAsFixed(1)} km',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class CompactListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final double? distanceKm;

  const CompactListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                kCategoryIcons[listing.category] ?? Icons.place_rounded,
                color: AppColors.accent,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              listing.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  listing.reviewCount > 0
                      ? listing.rating.toStringAsFixed(1)
                      : 'New',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (distanceKm != null) ...[
              const SizedBox(height: 2),
              Text(
                distanceKm! < 1
                    ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                    : '${distanceKm!.toStringAsFixed(1)} km',
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
