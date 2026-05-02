import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NoteCardShimmer extends StatelessWidget {
  final bool isGrid;
  const NoteCardShimmer({super.key, this.isGrid = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2840) : const Color(0xFFE8E6FF);
    final highlight =
        isDark ? const Color(0xFF3A3860) : const Color(0xFFF5F4FF);

    return isGrid ? _buildGrid(base, highlight) : _buildList(base, highlight);
  }

  Widget _buildGrid(Color base, Color highlight) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerCard(base, highlight),
    );
  }

  Widget _buildList(Color base, Color highlight) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 4,
      itemBuilder: (_, __) => _shimmerCard(base, highlight, isList: true),
    );
  }

  Widget _shimmerCard(Color base, Color highlight, {bool isList = false}) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            if (!isList) ...[
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  height: 22,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 10,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
