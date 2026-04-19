import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonTransactionItem extends StatelessWidget {
  const SkeletonTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: MediaQuery.of(context).size.width * 0.4, height: 14),
                const SizedBox(height: 6),
                SkeletonBox(width: MediaQuery.of(context).size.width * 0.25, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 64, height: 16),
        ],
      ),
    );
  }
}

class SkeletonTransactionList extends StatelessWidget {
  final int itemCount;

  const SkeletonTransactionList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => const SkeletonTransactionItem(),
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildFilterSkeleton()),
                const SizedBox(width: 16),
                Expanded(child: _buildFilterSkeleton()),
              ],
            ),
            const SizedBox(height: 16),
            _buildBalanceSkeleton(),
            const SizedBox(height: 16),
            _buildChartSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSkeleton() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBalanceSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 120, height: 12),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 52, borderRadius: 14),
          const SizedBox(height: 12),
          const Divider(),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 100, height: 12),
                SkeletonBox(width: 70, height: 12),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 150, height: 12),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 48, borderRadius: 30),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 200, borderRadius: 16),
          const SizedBox(height: 16),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: const [
                SkeletonBox(width: 10, height: 10, borderRadius: 5),
                SizedBox(width: 8),
                SkeletonBox(width: 80, height: 12),
                Spacer(),
                SkeletonBox(width: 50, height: 12),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
