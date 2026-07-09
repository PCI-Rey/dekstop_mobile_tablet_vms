import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class SkeletonVisitorCard extends StatelessWidget {
  const SkeletonVisitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonWidget(width: 80, height: 80, borderRadius: BorderRadius.all(Radius.circular(12))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(width: 120, height: 16),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          SkeletonWidget(width: 60, height: 20),
                          SizedBox(width: 8),
                          SkeletonWidget(width: 60, height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: const [
                    SkeletonWidget(width: 100, height: 14),
                    Spacer(),
                    SkeletonWidget(width: 150, height: 14),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class SkeletonOccupancyGrid extends StatelessWidget {
  const SkeletonOccupancyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SkeletonWidget(width: 24, height: 24, borderRadius: BorderRadius.all(Radius.circular(8))),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SkeletonWidget(width: 55, height: 8),
                      SizedBox(height: 4),
                      SkeletonWidget(width: 35, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonRelatedVisitors extends StatelessWidget {
  const SkeletonRelatedVisitors({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 1.3 : 0.9,
      ),
      itemCount: isMobile ? 2 : 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SkeletonWidget(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(18))),
                  SizedBox(height: 6),
                  SkeletonWidget(width: 60, height: 8),
                  SizedBox(height: 4),
                  SkeletonWidget(width: 40, height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonTimeline extends StatelessWidget {
  const SkeletonTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SkeletonWidget(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                const SizedBox(width: 12),
                const SkeletonWidget(width: 50, height: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonWidget(width: 120, height: 14),
                      SizedBox(height: 4),
                      SkeletonWidget(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}
