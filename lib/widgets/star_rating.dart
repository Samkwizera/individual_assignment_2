import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final int maxStars;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final val = rating - i;
        IconData icon;
        if (val >= 1) {
          icon = Icons.star_rounded;
        } else if (val >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: AppColors.accent, size: size);
      }),
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double size;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () {
            setState(() => _rating = (i + 1).toDouble());
            widget.onRatingChanged(_rating);
          },
          child: Icon(
            i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.accent,
            size: widget.size,
          ),
        );
      }),
    );
  }
}
