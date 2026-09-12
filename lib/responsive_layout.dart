import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double compactMaxWidth = 599.0;
  static const double medium = 600.0;
  static const double expanded = 1024.0;
}

class ResponsiveSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

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
  final Widget? right;
  final double breakpoint;
  final double spacing;

  const ResponsiveTwoColumnRow({
    super.key,
    required this.left,
    this.right,
    this.breakpoint = ResponsiveBreakpoints.medium,
    this.spacing = ResponsiveSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    if (right == null) {
      return left;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right!),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: spacing),
              right!,
            ],
          );
        }
      },
    );
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final double spacing;

  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.spacing = ResponsiveSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}

class ResponsiveFormActions extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  const ResponsiveFormActions({
    super.key,
    required this.children,
    this.breakpoint = ResponsiveBreakpoints.medium,
    this.spacing = ResponsiveSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                children[i],
              ],
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
      },
    );
  }
}
