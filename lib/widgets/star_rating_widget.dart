import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final void Function(int)? onRatingChanged;
  final Color color;
  final int starCount;

  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.color = Colors.amber,
    this.starCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starIndex = index + 1;
        final icon = rating >= starIndex
            ? Icons.star
            : rating >= starIndex - 0.5
                ? Icons.star_half
                : Icons.star_border;

        return GestureDetector(
          onTap: onRatingChanged == null
              ? null
              : () {
                  onRatingChanged!(starIndex);
                },
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        );
      }),
    );
  }
}
