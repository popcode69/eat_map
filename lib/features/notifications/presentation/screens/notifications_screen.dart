import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationEntity> _mockNotifications = [
    NotificationEntity(
      id: 'notif_001',
      title: '🚨 ZONE UNDER ATTACK',
      message: 'The Burger Bastion is currently being raided by raider: spice_raider!',
      type: 'attack',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationEntity(
      id: 'notif_002',
      title: '🛡️ CONQUEST SUCCESSFUL',
      message: 'You have successfully taken over Sushi Slayer Dojo and are now Warlord!',
      type: 'success',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    NotificationEntity(
      id: 'notif_003',
      title: '⚡ UPI CASHOUT COMPLETE',
      message: 'Your withdrawal request of ₹100 to raider@paytm has been processed successfully.',
      type: 'payout',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationEntity(
      id: 'notif_004',
      title: '⚔️ NEW RAID IN AREA',
      message: 'A new uncaptured Stronghold (Pizza Stronghold) has appeared in your Mumbai geofence sector.',
      type: 'attack',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text(
          'TACTICAL ALERTS',
          style: TextStyle(
            fontFamily: AppTypography.headingFont,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _mockNotifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: _mockNotifications.length,
              itemBuilder: (context, index) {
                final notif = _mockNotifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildNotificationItem(notif),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 48, color: AppColors.getOnSurfaceMuted(context)),
          const SizedBox(height: 10),
          Text(
            'All quiet in this sector.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.getOnSurfaceMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationEntity notif) {
    Color typeColor = AppColors.getPrimary(context);
    IconData typeIcon = Icons.notifications_active_outlined;

    if (notif.type == 'attack') {
      typeColor = AppColors.getError(context);
      typeIcon = Icons.gavel_outlined;
    } else if (notif.type == 'success') {
      typeColor = AppColors.getSuccess(context);
      typeIcon = Icons.shield_outlined;
    } else if (notif.type == 'payout') {
      typeColor = AppColors.getWarning(context);
      typeIcon = Icons.flash_on;
    }

    final String timeStr = DateFormat('dd MMM, hh:mm a').format(notif.createdAt);

    return InkWell(
      onTap: () {
        _triggerHaptic();
        // Simulate reading
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.getSurface(context)
              : AppColors.getSurface(context).withAlpha((255 * 0.9).toInt()),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.getBorder(context) : typeColor.withAlpha((255 * 0.5).toInt()),
            width: notif.isRead ? 1.2 : 1.6,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withAlpha((255 * 0.1).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.title,
                        style: AppTypography.labelLarge.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.message,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 14,
                      color: notif.isRead ? AppColors.getOnSurfaceMuted(context) : AppColors.getOnSurface(context),
                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
