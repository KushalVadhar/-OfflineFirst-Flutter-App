import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sync_controller.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncController>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isOnline && !syncProvider.isSyncing && syncProvider.pendingCount == 0) {
          return const SizedBox.shrink();
        }

        String label = "";
        IconData icon = Icons.cloud_off_rounded;
        Color color = Colors.black;

        if (!syncProvider.isOnline) {
          label = "OFFLINE — CHANGES QUEUED";
          icon = Icons.cloud_off_rounded;
          color = const Color(0xFFE53935);
        } else if (syncProvider.isSyncing) {
          label = "SYNCING ${syncProvider.pendingCount} ITEMS...";
          icon = Icons.sync_rounded;
          color = const Color(0xFF1A1B1E);
        } else if (syncProvider.pendingCount > 0) {
          label = "${syncProvider.pendingCount} ITEMS PENDING";
          icon = Icons.cloud_queue_rounded;
          color = Colors.amber[800]!;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
