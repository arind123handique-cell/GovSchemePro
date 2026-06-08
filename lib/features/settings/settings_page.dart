import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/local_image.dart';
import '../../widgets/section_card.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final Map<String, TextEditingController> _c =
      <String, TextEditingController>{};
  String _logoPath = '';
  String _signaturePath = '';
  bool _loading = true;

  TextEditingController _ctrl(String k) =>
      _c.putIfAbsent(k, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, String> s =
        await ref.read(settingsRepositoryProvider).all();
    _ctrl(SettingsRepository.kDepartment).text =
        s[SettingsRepository.kDepartment] ?? '';
    _ctrl(SettingsRepository.kOffice).text =
        s[SettingsRepository.kOffice] ?? '';
    _ctrl(SettingsRepository.kDivision).text =
        s[SettingsRepository.kDivision] ?? '';
    _ctrl(SettingsRepository.kOfficer).text =
        s[SettingsRepository.kOfficer] ?? '';
    _ctrl(SettingsRepository.kOfficerDesignation).text =
        s[SettingsRepository.kOfficerDesignation] ?? '';
    _logoPath = s[SettingsRepository.kLogoPath] ?? '';
    _signaturePath = s[SettingsRepository.kSignaturePath] ?? '';
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).setAll(<String, String>{
      SettingsRepository.kDepartment:
          _ctrl(SettingsRepository.kDepartment).text.trim(),
      SettingsRepository.kOffice: _ctrl(SettingsRepository.kOffice).text.trim(),
      SettingsRepository.kDivision:
          _ctrl(SettingsRepository.kDivision).text.trim(),
      SettingsRepository.kOfficer:
          _ctrl(SettingsRepository.kOfficer).text.trim(),
      SettingsRepository.kOfficerDesignation:
          _ctrl(SettingsRepository.kOfficerDesignation).text.trim(),
      SettingsRepository.kLogoPath: _logoPath,
      SettingsRepository.kSignaturePath: _signaturePath,
    });
    bumpRefresh(ref);
    if (mounted) UiHelpers.showSnack(context, 'Settings saved');
  }

  Future<void> _pickImage(bool logo) async {
    final XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (file == null) return;
    setState(() {
      if (logo) {
        _logoPath = file.path;
      } else {
        _signaturePath = file.path;
      }
    });
  }

  Future<void> _backup() async {
    final Uint8List bytes =
        await ref.read(backupServiceProvider).exportBackup();
    if (!mounted) return;
    await UiHelpers.exportAndNotify(context,
        bytes: bytes,
        filename:
            'GovSchemePro_Backup_${DateTime.now().millisecondsSinceEpoch}.json',
        mime: Mime.json);
  }

  Future<void> _restore() async {
    final bool ok = await UiHelpers.confirm(context,
        title: 'Restore backup',
        message:
            'Restoring will REPLACE all current data with the backup contents. Continue?',
        destructive: true,
        confirmLabel: 'Restore');
    if (!ok) return;
    final FilePickerResult? picked =
        await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final Uint8List? bytes = picked.files.first.bytes;
    if (bytes == null) {
      if (mounted) {
        UiHelpers.showSnack(context, 'Could not read file', error: true);
      }
      return;
    }
    final int restored =
        await ref.read(backupServiceProvider).restoreBackup(bytes);
    bumpRefresh(ref);
    if (mounted) {
      UiHelpers.showSnack(context, 'Restored $restored records');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                SectionCard(
                  title: 'Department & Office',
                  icon: Icons.apartment_outlined,
                  child: Column(
                    children: <Widget>[
                      _field(SettingsRepository.kDepartment, 'Department Name'),
                      _field(SettingsRepository.kOffice, 'Office Name'),
                      _field(SettingsRepository.kDivision, 'Division'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Officer Details',
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: <Widget>[
                      _field(SettingsRepository.kOfficer, 'Officer Name'),
                      _field(SettingsRepository.kOfficerDesignation,
                          'Designation'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Logo & Signature',
                  icon: Icons.image_outlined,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: _imagePicker('Logo', _logoPath, true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child:
                              _imagePicker('Signature', _signaturePath, false)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Backup & Restore',
                  icon: Icons.backup_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                          'Export the full offline database to a JSON file, or restore from a previous backup.',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: _backup,
                            icon: const Icon(Icons.download),
                            label: const Text('Export Backup'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _restore,
                            icon: const Icon(Icons.upload),
                            label: const Text('Restore Backup'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${AppConstants.appName} • ${AppConstants.appTagline}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _field(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: _ctrl(key),
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }

  Widget _imagePicker(String label, String path, bool logo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: path.isEmpty
              ? const Center(
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.textSecondary))
              : LocalImage(path, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => _pickImage(logo),
          child: Text(path.isEmpty ? 'Choose' : 'Change'),
        ),
      ],
    );
  }
}
