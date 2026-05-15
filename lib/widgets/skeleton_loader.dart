import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return SkeletonLoader(
          width: double.infinity,
          height: itemHeight,
          borderRadius: borderRadius,
        );
      },
    );
  }
}

class SkeletonGridLoader extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;
  final int crossAxisCount;
  final EdgeInsetsGeometry padding;

  const SkeletonGridLoader({
    super.key,
    this.itemCount = 6,
    this.childAspectRatio = 1.0,
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const SkeletonLoader(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 16,
        );
      },
    );
  }
}
