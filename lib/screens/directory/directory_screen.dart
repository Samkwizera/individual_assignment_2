import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/listing_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/category_filter_bar.dart';
import '../../widgets/loading_overlay.dart';
import '../listing_detail/listing_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchCtrl = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {
      // Location not available — app still works without it
    }
  }

  double? _distanceTo(double lat, double lon) {
    if (_currentPosition == null) return null;
    final distMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    );
    return distMeters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final listingProv = context.watch<ListingProvider>();
    final listings = listingProv.filteredListings;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city_rounded,
                    color: AppColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kigali City', style: AppTextStyles.heading1),
                      if (_currentPosition != null)
                        Row(
                          children: const [
                            Icon(Icons.my_location_rounded,
                                size: 11, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text('Location enabled',
                                style: AppTextStyles.caption),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),


            CategoryFilterBar(
              selected: listingProv.selectedCategory,
              categories: kCategories,
              onSelected: (cat) {
                context.read<ListingProvider>().setCategory(cat);
              },
            ),
            const SizedBox(height: 14),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    context.read<ListingProvider>().setSearchQuery(v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search for a service or place...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            context
                                .read<ListingProvider>()
                                .setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),


            Expanded(
              child: listingProv.isLoading
                  ? const AppLoadingIndicator()
                  : listingProv.errorMessage != null
                      ? EmptyState(
                          message: listingProv.errorMessage!,
                          icon: Icons.wifi_off_rounded,
                        )
                      : listings.isEmpty
                          ? EmptyState(
                              message: listingProv.searchQuery.isNotEmpty ||
                                      listingProv.selectedCategory != 'All'
                                  ? 'No listings found.\nTry a different search or category.'
                                  : 'No listings yet.\nBe the first to add one!',
                              icon: Icons.place_rounded,
                            )
                          : RefreshIndicator(
                              color: AppColors.accent,
                              backgroundColor: AppColors.card,
                              onRefresh: () async {
                                context
                                    .read<ListingProvider>()
                                    .subscribeToAllListings();
                              },
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 80),
                                children: [
                                  // Near You section (sorted by distance)
                                  if (_currentPosition != null &&
                                      listingProv.searchQuery.isEmpty &&
                                      listingProv.selectedCategory == 'All') ...[
                                    _buildNearYouSection(listings),
                                    const SizedBox(height: 20),
                                  ],

                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          listingProv.selectedCategory !=
                                                  'All'
                                              ? listingProv.selectedCategory
                                              : 'All Services',
                                          style: AppTextStyles.heading2,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.accent.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${listings.length}',
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...listings.map((l) => ListingCard(
                                        listing: l,
                                        distanceKm: _distanceTo(
                                            l.latitude, l.longitude),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ListingDetailScreen(
                                                    listing: l),
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearYouSection(List listings) {
    final nearby = List.from(listings);
    nearby.sort((a, b) {
      final da = _distanceTo(a.latitude, a.longitude) ?? double.infinity;
      final db = _distanceTo(b.latitude, b.longitude) ?? double.infinity;
      return da.compareTo(db);
    });
    final nearbyShort = nearby.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Near You', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nearbyShort.length,
            itemBuilder: (_, i) => CompactListingCard(
              listing: nearbyShort[i],
              distanceKm:
                  _distanceTo(nearbyShort[i].latitude, nearbyShort[i].longitude),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ListingDetailScreen(listing: nearbyShort[i])),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
