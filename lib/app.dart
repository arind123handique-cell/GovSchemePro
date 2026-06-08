import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class GovSchemeApp extends StatelessWidget {
  const GovSchemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
