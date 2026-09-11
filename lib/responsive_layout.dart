import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class ResponsiveTwoColumnRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double breakpoint;
  final double spacing;

  const ResponsiveTwoColumnRow({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 600.0,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              if (right is! SizedBox) SizedBox(height: spacing),
              if (right is! SizedBox) right,
            ],
          );
        }
      },
    );
  }
}
