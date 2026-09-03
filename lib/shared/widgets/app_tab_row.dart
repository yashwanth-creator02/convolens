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

class AppTabRow extends StatefulWidget {
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
  State<AppTabRow> createState() => _AppTabRowState();
}

class _AppTabRowState extends State<AppTabRow> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );
  }

  @override
  void didUpdateWidget(AppTabRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: widget.selectedIndex.clamp(0, widget.tabs.length - 1),
      );
    } else if (oldWidget.selectedIndex != widget.selectedIndex) {
      _tabController.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    Decoration? indicator;
    if (widget.indicator == AppTabIndicator.underline) {
      indicator = UnderlineTabIndicator(
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: widget.indicatorThickness,
        ),
        insets: widget.indicatorPadding,
      );
    } else if (widget.indicator == AppTabIndicator.pill) {
      indicator = _PillTabIndicator(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(widget.indicatorRadius),
        padding: widget.indicatorPadding,
      );
    }

    return Container(
      height: widget.height,
      padding: widget.padding,
      child: Theme(
        data: theme.copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: widget.scrollable,
          onTap: widget.onTabSelected,
          indicator: indicator,
          indicatorSize: widget.indicator == AppTabIndicator.pill
              ? TabBarIndicatorSize.tab
              : TabBarIndicatorSize.label,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabAlignment: widget.scrollable ? TabAlignment.start : null,
          tabs: widget.tabs.map((tab) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tab.icon != null) ...[
                  Icon(tab.icon, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(tab.label),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _PillTabIndicator extends Decoration {
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const _PillTabIndicator({
    required this.color,
    required this.borderRadius,
    required this.padding,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _PillPainter(this, onChanged);
  }
}

class _PillPainter extends BoxPainter {
  final _PillTabIndicator decoration;

  _PillPainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;

    final paddedRect = decoration.padding
        .resolve(configuration.textDirection)
        .deflateRect(rect);

    canvas.drawRRect(
      decoration.borderRadius.toRRect(paddedRect),
      paint,
    );
  }
}
