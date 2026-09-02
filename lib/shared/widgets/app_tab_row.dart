import 'package:flutter/material.dart';

enum AppTabIndicator {
  underline,
  pill,
  none,
}

class AppTabItem {
  final String label;
  final IconData? icon;

  const AppTabItem({
    required this.label,
    this.icon,
  });
}

class AppTabRow extends StatelessWidget {
  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final double height;

  final AppTabIndicator indicator;
  final double indicatorThickness;
  final double indicatorRadius;
  final EdgeInsetsGeometry indicatorPadding;

  const AppTabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.scrollable = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.height = 48,
    this.indicator = AppTabIndicator.underline,
    this.indicatorThickness = 2,
    this.indicatorRadius = 2,
    this.indicatorPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    if (scrollable) {
      return _buildScrollable(context);
    }

    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (int index = 0; index < tabs.length; index++)
              Expanded(
                child: _AppTab(
                  tab: tabs[index],
                  selected: index == selectedIndex,
                  onTap: () => onTabSelected(index),
                  isScrollable: false,
                  indicator: indicator,
                  indicatorThickness: indicatorThickness,
                  indicatorRadius: indicatorRadius,
                  indicatorPadding: indicatorPadding,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int index = 0; index < tabs.length; index++)
              _AppTab(
                tab: tabs[index],
                selected: index == selectedIndex,
                onTap: () => onTabSelected(index),
                isScrollable: true,
                indicator: indicator,
                indicatorThickness: indicatorThickness,
                indicatorRadius: indicatorRadius,
                indicatorPadding: indicatorPadding,
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTab extends StatelessWidget {
  final AppTabItem tab;
  final bool selected;
  final VoidCallback onTap;
  final bool isScrollable;

  final AppTabIndicator indicator;
  final double indicatorThickness;
  final double indicatorRadius;
  final EdgeInsetsGeometry indicatorPadding;

  const _AppTab({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.isScrollable,
    required this.indicator,
    required this.indicatorThickness,
    required this.indicatorRadius,
    required this.indicatorPadding,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(
                        tab.icon,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected && indicator != AppTabIndicator.none)
              _buildIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (indicator) {
      case AppTabIndicator.underline:
        return Padding(
          padding: indicatorPadding,
          child: Container(
            height: indicatorThickness,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                indicatorRadius,
              ),
              color: colorScheme.primary,
            ),
          ),
        );

      case AppTabIndicator.pill:
        return Padding(
          padding: indicatorPadding,
          child: Container(
            height: indicatorThickness + 8,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                indicatorRadius + 8,
              ),
              color: colorScheme.primaryContainer,
            ),
          ),
        );

      case AppTabIndicator.none:
        return const SizedBox.shrink();
    }
  }
}
