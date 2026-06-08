import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../schemes/create_scheme_page.dart';
import 'nav_destinations.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _select(int index) {
    setState(() => _index = index);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _createScheme() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateSchemePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DeviceType device = Responsive.of(context);
    final Widget body = IndexedStack(
      index: _index,
      children: kNavItems.map((NavItem item) => item.page).toList(),
    );

    if (device == DeviceType.mobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(kNavItems[_index].label),
        ),
        drawer: Drawer(child: _SidebarContent(selected: _index, onSelect: _select, onCreate: _createScheme)),
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createScheme,
          icon: const Icon(Icons.add),
          label: const Text('New Scheme'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: kBottomNavIndices.contains(_index)
              ? kBottomNavIndices.indexOf(_index)
              : 0,
          onDestinationSelected: (int i) => _select(kBottomNavIndices[i]),
          destinations: kBottomNavIndices
              .map((int i) => NavigationDestination(
                    icon: Icon(kNavItems[i].icon),
                    label: kNavItems[i].label.split(' ').first,
                  ))
              .toList(),
        ),
      );
    }

    final bool expanded = device == DeviceType.desktop;
    return Scaffold(
      body: Row(
        children: <Widget>[
          SizedBox(
            width: expanded ? 250 : 78,
            child: _SidebarContent(
              selected: _index,
              onSelect: _select,
              onCreate: _createScheme,
              compact: !expanded,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final bool compact;

  const _SidebarContent({
    required this.selected,
    required this.onSelect,
    required this.onCreate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 18),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.apartment, color: Colors.white, size: 28),
                  if (!compact) ...<Widget>[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ERP',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 14, vertical: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 18),
                label: Text(compact ? '' : 'Create Scheme'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: kNavItems.length,
                itemBuilder: (BuildContext context, int i) {
                  final bool isSelected = i == selected;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: compact ? 0 : 12),
                      horizontalTitleGap: 8,
                      leading: Icon(kNavItems[i].icon,
                          color: Colors.white,
                          size: 20),
                      title: compact
                          ? null
                          : Text(
                              kNavItems[i].label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13.5,
                              ),
                            ),
                      onTap: () => onSelect(i),
                    ),
                  );
                },
              ),
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Offline-first  •  v1.0',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
