import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'listings';

  Stream<List<ListingModel>> streamAllListings() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ListingModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<ListingModel>> streamUserListings(String uid) {
    return _db
        .collection(_col)
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ListingModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<ListingModel>> streamListingsByCategory(String category) {
    if (category == 'All') return streamAllListings();
    return _db
        .collection(_col)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ListingModel.fromFirestore(d)).toList(),
        );
  }

  Future<String> createListing(ListingModel listing) async {
    final docRef = _db.collection(_col).doc();
    unawaited(
      docRef.set(listing.toMap()).catchError((Object e) {
        debugPrint('[ListingService] createListing error: $e');
      }),
    );
    return docRef.id;
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _db.collection(_col).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteListing(String id) async {
    final reviews = await _db
        .collection('reviews')
        .where('listingId', isEqualTo: id)
        .get();

    final batch = _db.batch();
    for (final doc in reviews.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection(_col).doc(id));
    await batch.commit();
  }

  Future<ListingModel?> getListing(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  Future<void> updateListingRating(
    String listingId,
    double newRating,
    int newReviewCount,
  ) async {
    await _db.collection(_col).doc(listingId).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
  }
}
