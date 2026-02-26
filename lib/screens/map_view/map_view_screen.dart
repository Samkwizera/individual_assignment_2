import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  ListingModel? _selectedListing;

  // Default camera: Kigali City Centre
  static const CameraPosition _kigaliCenter = CameraPosition(
    target: LatLng(-1.9441, 30.0619),
    zoom: 13.5,
  );

  Set<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((l) {
      return Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.latitude, l.longitude),
        infoWindow: InfoWindow(
          title: l.name,
          snippet: '${l.category} • ${l.address}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _categoryHue(l.category),
        ),
        onTap: () {
          setState(() => _selectedListing = l);
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(l.latitude, l.longitude),
                zoom: 16,
              ),
            ),
          );
        },
      );
    }).toSet();
  }

  double _categoryHue(String category) {
    switch (category) {
      case 'Hospital':
        return BitmapDescriptor.hueRed;
      case 'Police Station':
        return BitmapDescriptor.hueBlue;
      case 'Library':
        return BitmapDescriptor.hueGreen;
      case 'Restaurant':
        return BitmapDescriptor.hueOrange;
      case 'Café':
        return BitmapDescriptor.hueYellow;
      case 'Park':
        return BitmapDescriptor.hueCyan;
      case 'Tourist Attraction':
        return BitmapDescriptor.hueMagenta;
      case 'Pharmacy':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueViolet;
    }
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
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_kigaliCenter),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────────
          listingProv.isLoading
              ? const AppLoadingIndicator()
              : GoogleMap(
                  initialCameraPosition: _kigaliCenter,
                  markers: _buildMarkers(listings),
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    controller.setMapStyle(_mapStyle);
                  },
                  onTap: (_) => setState(() => _selectedListing = null),
                ),

          // ── Category Filter Overlay ───────────────────────────────────────
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

          // ── Count Badge ───────────────────────────────────────────────────
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

          // ── Selected Listing Card ─────────────────────────────────────────
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

  // Dark map style to match app theme
  static const String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8892a4"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#0a1628"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#162033"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#1c2b42"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1f33"}]},
    {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#0d2a1a"}]}
  ]
  ''';
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
