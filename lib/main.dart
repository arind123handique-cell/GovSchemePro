import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'services/seed/seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initFactory();
  await SeedService(AppDatabase.instance).seedIfEmpty();
  runApp(const ProviderScope(child: GovSchemeApp()));
}
