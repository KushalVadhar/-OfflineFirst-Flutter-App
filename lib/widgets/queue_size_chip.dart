import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sync_controller.dart';

class QueueSizeChip extends StatelessWidget {
  const QueueSizeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncController>(
      builder: (context, syncProvider, child) {
        final pendingCount = syncProvider.pendingCount;
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Chip(
            padding: EdgeInsets.zero,
            label: Text("⏳ $pendingCount PENDING"),
            backgroundColor: pendingCount > 0 ? Colors.amber[100] : Colors.green[100],
            shape: const RoundedRectangleBorder(),
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: pendingCount > 0 ? Colors.amber[900] : Colors.green[900],
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontFamily: 'serif',
            ),
          ),
        );
      },
    );
  }
}
