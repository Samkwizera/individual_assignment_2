import 'dart:async';
import 'package:flutter/material.dart';
import '../services/listing_service.dart';
import '../services/review_service.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService;
  final ReviewService _reviewService;

  List<ListingModel> _allListings = [];
  List<ListingModel> _userListings = [];
  List<ReviewModel> _currentReviews = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isUserListingsLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  StreamSubscription<List<ListingModel>>? _allListingsSub;
  StreamSubscription<List<ListingModel>>? _userListingsSub;
  StreamSubscription<List<ReviewModel>>? _reviewsSub;

  ListingProvider(this._listingService, this._reviewService);

  bool get isLoading => _isLoading;
  bool get isUserListingsLoading => _isUserListingsLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<ReviewModel> get currentReviews => _currentReviews;
  List<ListingModel> get userListings => _userListings;

  List<ListingModel> get filteredListings {
    List<ListingModel> result = List.from(_allListings);

    if (_selectedCategory != 'All') {
      result = result.where((l) => l.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((l) {
        return l.name.toLowerCase().contains(query) ||
            l.address.toLowerCase().contains(query) ||
            l.category.toLowerCase().contains(query) ||
            l.description.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  void subscribeToAllListings() {
    _allListingsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _allListingsSub = _listingService.streamAllListings().listen(
      (listings) {
        _allListings = listings;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load listings. Check your connection.';
        notifyListeners();
      },
    );
  }

  void subscribeToUserListings(String uid) {
    _userListingsSub?.cancel();
    _isUserListingsLoading = true;
    notifyListeners();
    _userListingsSub = _listingService
        .streamUserListings(uid)
        .listen(
          (listings) {
            _userListings = listings;
            _isUserListingsLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _isUserListingsLoading = false;
            notifyListeners();
          },
        );
  }

  void subscribeToReviews(String listingId) {
    _reviewsSub?.cancel();
    _reviewsSub = _reviewService.streamReviews(listingId).listen((reviews) {
      _currentReviews = reviews;
      notifyListeners();
    });
  }

  void cancelReviewSubscription() {
    _reviewsSub?.cancel();
    _currentReviews = [];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> createListing(ListingModel listing) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _listingService.createListing(listing);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create listing. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateListing(String id, Map<String, dynamic> data) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.updateListing(id, data);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update listing. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteListing(String id) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.deleteListing(id);
    
      _userListings = _userListings.where((l) => l.id != id).toList();
      _allListings = _allListings.where((l) => l.id != id).toList();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete listing. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required String listingId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final alreadyReviewed = await _reviewService.hasUserReviewed(
        listingId,
        userId,
      );
      if (alreadyReviewed) {
        _errorMessage = 'You have already reviewed this place.';
        return false;
      }

      final review = ReviewModel(
        id: '',
        listingId: listingId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _reviewService.addReview(review);

      final ratingData = await _reviewService.getAverageRating(listingId);
      await _listingService.updateListingRating(
        listingId,
        (ratingData['rating'] as double),
        (ratingData['count'] as int),
      );

      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit review. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  ListingModel? getListingById(String id) {
    try {
      return _allListings.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _allListingsSub?.cancel();
    _userListingsSub?.cancel();
    _reviewsSub?.cancel();
    super.dispose();
  }
}
