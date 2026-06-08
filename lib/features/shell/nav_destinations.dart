import 'package:flutter/material.dart';

import '../bills/bills_page.dart';
import '../certificates/certificates_page.dart';
import '../contractors/contractors_page.dart';
import '../dashboard/dashboard_page.dart';
import '../documents/documents_page.dart';
import '../reports/reports_page.dart';
import '../schemes/scheme_register_page.dart';
import '../settings/settings_page.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget page;

  const NavItem({required this.label, required this.icon, required this.page});
}

/// Primary navigation destinations rendered in the sidebar / drawer.
const List<NavItem> kNavItems = <NavItem>[
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, page: DashboardPage()),
  NavItem(
      label: 'Scheme Register',
      icon: Icons.account_tree_outlined,
      page: SchemeRegisterPage()),
  NavItem(label: 'Contractors', icon: Icons.engineering_outlined, page: ContractorsPage()),
  NavItem(label: 'Bills', icon: Icons.receipt_long_outlined, page: BillsPage()),
  NavItem(
      label: 'Certificates',
      icon: Icons.workspace_premium_outlined,
      page: CertificatesPage()),
  NavItem(label: 'Reports', icon: Icons.bar_chart_outlined, page: ReportsPage()),
  NavItem(label: 'Documents', icon: Icons.folder_outlined, page: DocumentsPage()),
  NavItem(label: 'Settings', icon: Icons.settings_outlined, page: SettingsPage()),
];

/// Indices surfaced in the mobile bottom navigation bar.
const List<int> kBottomNavIndices = <int>[0, 1, 3, 5];
