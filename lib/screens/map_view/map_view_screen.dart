import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/listing_provider.dart';
import '../../models/listing_model.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_overlay.dart';
import '../listing_detail/listing_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  ListingModel? _selectedListing;

  static const LatLng _kigaliCenter = LatLng(-1.9441, 30.0619);
  static const double _defaultZoom = 13.5;

  List<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((l) {
      final color = kCategoryColors[l.category] ?? AppColors.accent;
      final icon = kCategoryIcons[l.category] ?? Icons.place_rounded;
      return Marker(
        point: LatLng(l.latitude, l.longitude),
        width: 38,
        height: 38,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedListing = l);
            _mapController.move(LatLng(l.latitude, l.longitude), 16);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingProv = context.watch<ListingProvider>();
    final listings = listingProv.filteredListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController.move(_kigaliCenter, _defaultZoom);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          listingProv.isLoading
              ? const AppLoadingIndicator()
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _kigaliCenter,
                    initialZoom: _defaultZoom,
                    onTap: (_, __) => setState(() => _selectedListing = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapboxDarkTileUrl,
                      userAgentPackageName: 'com.kigali.kigaliCityDirectory',
                      maxZoom: 19,
                      tileSize: 512,
                      zoomOffset: -1,
                    ),
                    MarkerLayer(markers: _buildMarkers(listings)),
                  ],
                ),

          // ── Category Filter Overlay ─────────────────────────────────────
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = kCategories[i];
                  final isSelected = cat == listingProv.selectedCategory;
                  return GestureDetector(
                    onTap: () => context.read<ListingProvider>().setCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.background
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Count Badge ─────────────────────────────────────────────────
          Positioned(
            top: 58,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                '${listings.length} place${listings.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ── Selected Listing Card ───────────────────────────────────────
          if (_selectedListing != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _SelectedListingCard(
                listing: _selectedListing!,
                onClose: () => setState(() => _selectedListing = null),
                onViewDetails: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ListingDetailScreen(listing: _selectedListing!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _SelectedListingCard({
    required this.listing,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                Text(listing.name, style: AppTextStyles.heading3),
                const SizedBox(height: 2),
                Text(
                  '${listing.category} · ${listing.shortAddress}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onViewDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
