import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_overlay.dart';

class ListingFormScreen extends StatefulWidget {
  final ListingModel? listing;

  const ListingFormScreen({super.key, this.listing});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  String _selectedCategory = kCategories[1];
  final MapController _mapController = MapController();
  LatLng? _pickedLocation;

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameCtrl = TextEditingController(text: l?.name ?? '');
    _addressCtrl = TextEditingController(text: l?.address ?? '');
    _contactCtrl = TextEditingController(text: l?.contactNumber ?? '');
    _descCtrl = TextEditingController(text: l?.description ?? '');
    _latCtrl = TextEditingController(
        text: l != null ? l.latitude.toStringAsFixed(6) : '');
    _lngCtrl = TextEditingController(
        text: l != null ? l.longitude.toStringAsFixed(6) : '');

    if (l != null) {
      _selectedCategory = l.category;
      _pickedLocation = LatLng(l.latitude, l.longitude);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showSnack('Location services are disabled.', isError: true);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium),
      );
      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _pickedLocation = newLoc;
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      });
      _mapController.move(newLoc, 16);
    } catch (e) {
      _showSnack('Could not get location. Enter coordinates manually.',
          isError: true);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _pickedLocation = latlng;
      _latCtrl.text = latlng.latitude.toStringAsFixed(6);
      _lngCtrl.text = latlng.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());

    if (lat == null || lng == null) {
      _showSnack('Please enter valid coordinates.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    final authProv = context.read<AuthProvider>();
    final listingProv = context.read<ListingProvider>();
    final user = authProv.userModel!;

    if (_isEditing) {
      final data = {
        'name': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'address': _addressCtrl.text.trim(),
        'contactNumber': _contactCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'latitude': lat,
        'longitude': lng,
      };
      final success = await listingProv.updateListing(widget.listing!.id, data);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Listing updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        _showSnack(
            listingProv.errorMessage ?? 'Failed. Please try again.',
            isError: true);
      }
    } else {
      final newListing = ListingModel(
        id: '',
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        address: _addressCtrl.text.trim(),
        contactNumber: _contactCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        createdBy: user.uid,
        createdByName: user.displayName,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Listing created successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));

      listingProv.createListing(newListing);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final listingProv = context.watch<ListingProvider>();

    return LoadingOverlay(
      isLoading: listingProv.isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Listing' : 'Add Listing'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: listingProv.isSubmitting ? null : _submit,
              child: Text(
                _isEditing ? 'Update' : 'Publish',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Basic Information'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Place / Service Name *',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  _sectionLabel('Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCategories.skip(1).map((cat) {
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent
                                : AppColors.chipUnselected,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.background
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),


                  _sectionLabel('Location & Contact'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressCtrl,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'e.g. KN 5 Ave, Kigali',
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _contactCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Contact Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: 'e.g. +250 788 000 000',
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Contact number is required' : null,
                  ),
                  const SizedBox(height: 20),


                  _sectionLabel('Description'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      alignLabelWithHint: true,
                      hintText: 'Describe this place or service...',
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 24),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel('GPS Coordinates'),
                      TextButton.icon(
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Use Current'),
                        onPressed: _useCurrentLocation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the map below to pick a location, or enter coordinates manually.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Latitude *',
                            hintText: '-1.9441',
                          ),
                          onChanged: (v) {
                            final lat = double.tryParse(v);
                            final lng = double.tryParse(_lngCtrl.text);
                            if (lat != null && lng != null) {
                              setState(() {
                                _pickedLocation = LatLng(lat, lng);
                              });
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Latitude required';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Longitude *',
                            hintText: '30.0619',
                          ),
                          onChanged: (v) {
                            final lng = double.tryParse(v);
                            final lat = double.tryParse(_latCtrl.text);
                            if (lat != null && lng != null) {
                              setState(() {
                                _pickedLocation = LatLng(lat, lng);
                              });
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Longitude required';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),


                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _pickedLocation ??
                                  const LatLng(-1.9441, 30.0619),
                              initialZoom: 13.5,
                              onTap: _onMapTap,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: mapboxDarkTileUrl,
                                userAgentPackageName:
                                    'com.kigali.kigaliCityDirectory',
                                maxZoom: 19,
                                tileSize: 512,
                                zoomOffset: -1,
                              ),
                              if (_pickedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _pickedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: AppColors.accent,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (_pickedLocation == null)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Tap to place marker',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),


                  ElevatedButton(
                    onPressed: listingProv.isSubmitting ? null : _submit,
                    child: listingProv.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.background),
                          )
                        : Text(_isEditing ? 'Update Listing' : 'Publish Listing'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
