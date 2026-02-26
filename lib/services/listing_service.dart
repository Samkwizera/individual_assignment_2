import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'listings';

  // ─── Stream: All Listings (real-time) ──────────────────────────────────────
  Stream<List<ListingModel>> streamAllListings() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ListingModel.fromFirestore(d)).toList());
  }

  // ─── Stream: Listings by User ───────────────────────────────────────────────
  Stream<List<ListingModel>> streamUserListings(String uid) {
    return _db
        .collection(_col)
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ListingModel.fromFirestore(d)).toList());
  }

  // ─── Stream: Listings by Category ──────────────────────────────────────────
  Stream<List<ListingModel>> streamListingsByCategory(String category) {
    if (category == 'All') return streamAllListings();
    return _db
        .collection(_col)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ListingModel.fromFirestore(d)).toList());
  }

  // ─── Create Listing ─────────────────────────────────────────────────────────
  Future<String> createListing(ListingModel listing) async {
    final docRef = await _db.collection(_col).add(listing.toMap());
    return docRef.id;
  }

  // ─── Update Listing ─────────────────────────────────────────────────────────
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _db.collection(_col).doc(id).update(data);
  }

  // ─── Delete Listing ─────────────────────────────────────────────────────────
  Future<void> deleteListing(String id) async {
    // Also delete all reviews for this listing
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

  // ─── Get Single Listing ─────────────────────────────────────────────────────
  Future<ListingModel?> getListing(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  // ─── Update Listing Rating ──────────────────────────────────────────────────
  Future<void> updateListingRating(
      String listingId, double newRating, int newReviewCount) async {
    await _db.collection(_col).doc(listingId).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
  }
}
