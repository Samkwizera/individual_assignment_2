import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/loading_overlay.dart';
import '../listing_detail/listing_detail_screen.dart';
import '../listing_form/listing_form_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final listingProv = context.watch<ListingProvider>();
    final myListings = listingProv.userListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.accent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListingFormScreen()),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: listingProv.isSubmitting,
        child: SafeArea(
          child: Column(
            children: [
              if (authProv.userModel != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            authProv.userModel!.displayName.isNotEmpty
                                ? authProv.userModel!.displayName[0]
                                      .toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProv.userModel!.displayName,
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${myListings.length} listing${myListings.length != 1 ? 's' : ''} created',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_rounded,
                          color: AppColors.accent,
                          size: 28,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListingFormScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: listingProv.isUserListingsLoading
                    ? const AppLoadingIndicator()
                    : myListings.isEmpty
                    ? EmptyState(
                        message:
                            'You haven\'t added any listings yet.\nTap the + button to add your first one!',
                        icon: Icons.add_location_alt_rounded,
                        actionLabel: 'Add Listing',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListingFormScreen(),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: myListings.length,
                        itemBuilder: (_, i) {
                          final listing = myListings[i];
                          return Stack(
                            children: [
                              ListingCard(
                                listing: listing,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ListingDetailScreen(listing: listing),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Row(
                                  children: [
                                    _ActionChip(
                                      icon: Icons.edit_rounded,
                                      color: AppColors.accent,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ListingFormScreen(
                                            listing: listing,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _ActionChip(
                                      icon: Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      onTap: () => _confirmDelete(
                                        context,
                                        listing.id,
                                        listing.name,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ListingFormScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String listingId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Listing', style: AppTextStyles.heading3),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
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
                  .deleteListing(listingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Listing deleted successfully.'
                          : context.read<ListingProvider>().errorMessage ??
                                'Failed to delete listing.',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
