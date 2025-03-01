import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        final isSyncing = provider.isLoading || provider.isSaving;

        return AnimatedOpacity(
          opacity: isSyncing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Tooltip(
            message: 'Syncing with Nextcloud',
            child: RotationTransition(
              turns: _controller,
              child: const Icon(
                Icons.sync,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}
