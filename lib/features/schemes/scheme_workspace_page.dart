import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ui_helpers.dart';
import '../../data/models/scheme.dart';
import '../../providers/data_providers.dart';
import 'create_scheme_page.dart';
import 'tabs/boq_tab.dart';
import 'tabs/bills_tab.dart';
import 'tabs/certificates_tab.dart';
import 'tabs/documents_tab.dart';
import 'tabs/mb_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/photos_tab.dart';
import 'tabs/progress_tab.dart';

class SchemeWorkspacePage extends ConsumerWidget {
  final String schemeId;
  const SchemeWorkspacePage({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Scheme?> scheme = ref.watch(schemeByIdProvider(schemeId));

    return scheme.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (Object e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (Scheme? s) {
        if (s == null) {
          return const Scaffold(
              body: Center(child: Text('Scheme not found')));
        }
        return DefaultTabController(
          length: 8,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(s.schemeName,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(s.id,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Edit Scheme',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => CreateSchemePage(existing: s)));
                    bumpRefresh(ref);
                  },
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  Tab(text: 'Overview'),
                  Tab(text: 'BOQ'),
                  Tab(text: 'Measurement Book'),
                  Tab(text: 'Bills'),
                  Tab(text: 'Certificates'),
                  Tab(text: 'Progress'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                OverviewTab(scheme: s),
                BoqTab(schemeId: s.id),
                MbTab(schemeId: s.id),
                BillsTab(schemeId: s.id),
                CertificatesTab(schemeId: s.id),
                ProgressTab(schemeId: s.id),
                PhotosTab(schemeId: s.id),
                DocumentsTab(schemeId: s.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shared empty action used by tabs.
class TabPadding extends StatelessWidget {
  final Widget child;
  const TabPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(16), child: child);
}

extension SnackContext on BuildContext {
  void snack(String message) => UiHelpers.showSnack(this, message);
}
