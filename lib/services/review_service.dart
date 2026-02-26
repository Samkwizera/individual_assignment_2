import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'reviews';

  Stream<List<ReviewModel>> streamReviews(String listingId) {
    return _db
        .collection(_col)
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ReviewModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> addReview(ReviewModel review) async {
    await _db.collection(_col).add(review.toMap());
  }

  Future<bool> hasUserReviewed(String listingId, String userId) async {
    final snap = await _db
        .collection(_col)
        .where('listingId', isEqualTo: listingId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>> getAverageRating(String listingId) async {
    final snap = await _db
        .collection(_col)
        .where('listingId', isEqualTo: listingId)
        .get();

    if (snap.docs.isEmpty) return {'rating': 0.0, 'count': 0};

    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['rating'] as num).toDouble();
    }
    final avg = total / snap.docs.length;
    return {'rating': avg, 'count': snap.docs.length};
  }
}
