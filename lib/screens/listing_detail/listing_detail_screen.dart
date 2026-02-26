import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/star_rating.dart';
import '../listing_form/listing_form_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late ListingModel _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    // Subscribe to real-time reviews for this listing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().subscribeToReviews(_listing.id);
    });
  }

  @override
  void dispose() {
    context.read<ListingProvider>().cancelReviewSubscription();
    super.dispose();
  }

  Future<void> _launchNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${_listing.latitude},${_listing.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch Google Maps navigation.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _callNumber() async {
    final url = Uri.parse('tel:${_listing.contactNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showReviewDialog() {
    final authProv = context.read<AuthProvider>();
    if (authProv.userModel == null) return;

    double selectedRating = 0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate This Service', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(_listing.name, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 20),
            const Text('Your Rating', style: AppTextStyles.body),
            const SizedBox(height: 10),
            InteractiveStarRating(
              onRatingChanged: (r) => selectedRating = r,
              size: 40,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Your Review',
                hintText: 'Share your experience...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Consumer<ListingProvider>(
              builder: (ctx, prov, _) => ElevatedButton(
                onPressed: prov.isSubmitting
                    ? null
                    : () async {
                        if (selectedRating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a rating.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        final success = await context
                            .read<ListingProvider>()
                            .addReview(
                              listingId: _listing.id,
                              userId: authProv.userModel!.uid,
                              userName: authProv.userModel!.displayName,
                              rating: selectedRating,
                              comment: commentCtrl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success
                                ? 'Review submitted! Thank you.'
                                : context
                                        .read<ListingProvider>()
                                        .errorMessage ??
                                    'Failed to submit review.'),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                child: prov.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.background),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final listingProv = context.watch<ListingProvider>();
    final isOwner = authProv.userModel?.uid == _listing.createdBy;
    final reviews = listingProv.currentReviews;

    // Keep listing in sync from provider if updated
    final updated = listingProv.getListingById(_listing.id);
    if (updated != null) _listing = updated;

    return Scaffold(
      appBar: AppBar(
        title: Text(_listing.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              color: AppColors.card,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingFormScreen(listing: _listing),
                    ),
                  );
                } else if (val == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppColors.accent, size: 18),
                      SizedBox(width: 10),
                      Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 10),
                      Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Map Section ───────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_listing.latitude, _listing.longitude),
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(_listing.id),
                        position: LatLng(_listing.latitude, _listing.longitude),
                        infoWindow: InfoWindow(title: _listing.name),
                      ),
                    },
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                  // Navigate button overlay
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: _launchNavigation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation_rounded,
                                color: AppColors.background, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Navigate',
                              style: TextStyle(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Details ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          kCategoryIcons[_listing.category] ??
                              Icons.place_rounded,
                          color: AppColors.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _listing.category,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(_listing.name, style: AppTextStyles.heading1),
                  const SizedBox(height: 8),

                  // Rating
                  if (_listing.reviewCount > 0) ...[
                    Row(
                      children: [
                        StarRating(rating: _listing.rating),
                        const SizedBox(width: 8),
                        Text(
                          '${_listing.rating.toStringAsFixed(1)} (${_listing.reviewCount} reviews)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Description
                  Text(
                    _listing.description,
                    style: AppTextStyles.bodySecondary.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 12),

                  // Info rows
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: _listing.address,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Contact',
                    value: _listing.contactNumber,
                    onTap: _callNumber,
                    valueColor: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Added by',
                    value: _listing.createdByName.isNotEmpty
                        ? _listing.createdByName
                        : 'Community Member',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Listed on',
                    value: DateFormat('MMM d, yyyy').format(_listing.createdAt),
                  ),
                  const SizedBox(height: 24),

                  // Rate this service button
                  ElevatedButton.icon(
                    onPressed: authProv.isAuthenticated
                        ? _showReviewDialog
                        : null,
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Rate This Service'),
                  ),
                  if (!authProv.isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Sign in to leave a review',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Reviews Section ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: AppTextStyles.heading2),
                      if (_listing.reviewCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _listing.reviewCount.toString(),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  reviews.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Center(
                            child: Text(
                              'No reviews yet. Be the first to review!',
                              style: AppTextStyles.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: reviews
                              .map((r) => _ReviewCard(review: r))
                              .toList(),
                        ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Listing', style: AppTextStyles.heading3),
        content: Text(
          'Delete "${_listing.name}"? This cannot be undone.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<ListingProvider>()
                  .deleteListing(_listing.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Listing deleted.'
                      : 'Failed to delete listing.'),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: valueColor,
                    decoration: onTap != null
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StarRating(rating: review.rating, size: 13),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${review.comment}"',
              style: AppTextStyles.bodySecondary.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
