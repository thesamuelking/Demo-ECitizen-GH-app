import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghanaserve/providers/theme_provider.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Appearance', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text('Choose how E-citizen looks on your device.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Card(child: Column(children: [
          RadioListTile<ThemeMode>(value: ThemeMode.light, groupValue: mode, onChanged: (value) => ref.read(themeModeProvider.notifier).state = value!, title: const Text('Light mode'), subtitle: const Text('Bright and easy to scan')),
          RadioListTile<ThemeMode>(value: ThemeMode.dark, groupValue: mode, onChanged: (value) => ref.read(themeModeProvider.notifier).state = value!, title: const Text('Dark mode'), subtitle: const Text('Comfortable in low light')),
        ])),
        const SizedBox(height: 18),
        Card(child: SwitchListTile(value: mode == ThemeMode.dark, onChanged: (value) => ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light, title: const Text('Dark mode'), subtitle: const Text('Use a darker colour scheme'), secondary: const Icon(Icons.dark_mode_outlined))),
      ]),
    );
  }
}
