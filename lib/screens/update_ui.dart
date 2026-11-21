import 'package:flutter/material.dart';

import '../services/updater.dart';

/// A slim strip above the tabs when a newer build is out.
class UpdateBanner extends StatelessWidget {
  final Updater updater;
  const UpdateBanner({super.key, required this.updater});

  @override
  Widget build(BuildContext context) {
    if (!updater.hasUpdate || (updater.dismissed && !updater.downloading)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final update = updater.available!;
    final progress = updater.downloadProgress;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.system_update, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress == null
                      ? 'Version ${update.versionName} (${update.versionCode}) is available'
                      : progress < 0
                          ? 'Downloading update…'
                          : 'Downloading update… ${(progress * 100).round()}%',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              if (progress == null) ...[
                TextButton(onPressed: () => showAboutSheet(context, updater), child: const Text('Details')),
                IconButton(
                  tooltip: 'Not now',
                  icon: Icon(Icons.close, color: scheme.onPrimaryContainer),
                  onPressed: updater.dismiss,
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Version info, what's new, and a manual "check for updates".
Future<void> showAboutSheet(BuildContext context, Updater updater) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: updater,
      builder: (context, _) {
        final theme = Theme.of(context);
        final update = updater.available;
        final progress = updater.downloadProgress;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pantry Chef', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  updater.supported
                      ? 'Installed: ${updater.installedName} (${updater.installedCode})'
                      : 'Updates are only available in the Android app.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (updater.hasUpdate) ...[
                  Text('New: ${update!.versionName} (${update.versionCode})', style: theme.textTheme.titleMedium),
                  if (update.changes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.35),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [for (final c in update.changes) Text('•  $c')],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (progress != null)
                    LinearProgressIndicator(value: progress < 0 ? null : progress)
                  else
                    FilledButton.icon(
                      onPressed: updater.downloadAndInstall,
                      icon: const Icon(Icons.download),
                      label: const Text('Download and install'),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Android asks you to confirm the install. Your ingredients and dishes are kept.',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (updater.supported)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          updater.checking
                              ? 'Checking for updates…'
                              : updater.lastCheck == null
                                  ? 'Not checked yet'
                                  : 'You have the latest version',
                        ),
                      ),
                      TextButton(
                        onPressed: updater.checking ? null : () => updater.check(force: true),
                        child: const Text('Check now'),
                      ),
                    ],
                  ),
                if (updater.error != null) ...[
                  const SizedBox(height: 8),
                  Text(updater.error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
