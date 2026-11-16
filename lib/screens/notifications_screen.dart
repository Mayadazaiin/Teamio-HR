import 'package:flutter/material.dart';
import 'package:teamio_hr/models/leave_request.dart';
import 'package:teamio_hr/services/leave_service.dart';

class NotificationsScreen extends StatefulWidget {
  final dynamic user;
  final VoidCallback? onNavigateToLeaves;

  const NotificationsScreen({
    super.key,
    required this.user,
    this.onNavigateToLeaves,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Unified Executive SaaS Palette
  static const Color _bgCanvas = Color(0xFF060913);
  static const Color _cardSurface = Color(0xFF111729);
  static const Color _cardElevated = Color(0xFF182038);
  static const Color _cyanGlow = Color(0xFF38BDF8);
  static const Color _indigoGlow = Color(0xFF818CF8);
  static const Color _emeraldLive = Color(0xFF10B981);
  static const Color _amberWarn = Color(0xFFF59E0B);
  static const Color _coralStop = Color(0xFFF43F5E);

  late Future<List<LeaveRequest>> _futureLeaves;
  final Set<String> _dismissedIds = {};

  String get _currentUserId {
    try {
      return (widget.user is Map ? widget.user['id'] : widget.user.id).toString();
    } catch (_) {
      return widget.user.toString();
    }
  }

  String get _currentUserRole {
    try {
      final role = (widget.user is Map ? widget.user['role'] : widget.user.role)?.toString().toLowerCase() ?? '';
      final level = (widget.user is Map ? widget.user['level'] : widget.user.level)?.toString().toLowerCase() ?? '';

      if (role == 'hr') return 'hr';
      if (level.isNotEmpty) return level;
      return role;
    } catch (_) {
      return '';
    }
  }

  bool get _isApproverRole {
    return ['senior', 'team lead', 'team leader', 'hr', 'manager']
        .contains(_currentUserRole.trim().toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _futureLeaves = LeaveService.getAccessibleLeaves(_currentUserId);
    });
  }

  List<_NotificationItem> _buildNotificationList(List<LeaveRequest> leaves) {
    final List<_NotificationItem> items = [];

    for (final leave in leaves) {
      if (_dismissedIds.contains(leave.id)) continue;

      final isOwnRequest = leave.userId.toLowerCase() == _currentUserId.toLowerCase();
      final status = leave.status.trim().toLowerCase();

      // 1. Seniors / Team Leaders / HR -> Pending requests from juniors/team
      if (_isApproverRole && !isOwnRequest && status == 'pending') {
        items.add(
          _NotificationItem(
            id: leave.id,
            title: 'Pending Leave Request',
            message: '${leave.employeeName} requested ${leave.type} (${leave.dateRange}).',
            tag: 'ACTION REQUIRED',
            accentColor: _amberWarn,
            icon: Icons.pending_actions_rounded,
            leave: leave,
            isActionable: true,
          ),
        );
      }

      // 2. Juniors (and own requests) -> Approved or Rejected updates
      if (isOwnRequest && (status == 'approved' || status == 'rejected')) {
        final isApproved = status == 'approved';
        items.add(
          _NotificationItem(
            id: leave.id,
            title: isApproved ? 'Leave Request Approved' : 'Leave Request Declined',
            message: isApproved
                ? 'Your ${leave.type} for ${leave.dateRange} has been approved.'
                : 'Your ${leave.type} for ${leave.dateRange} was declined.',
            tag: isApproved ? 'APPROVED' : 'REJECTED',
            accentColor: isApproved ? _emeraldLive : _coralStop,
            icon: isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            leave: leave,
            isActionable: false,
          ),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      appBar: AppBar(
        backgroundColor: _bgCanvas,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: _cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _cyanGlow, size: 20),
              onPressed: _loadNotifications,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveRequest>>(
        future: _futureLeaves,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _cyanGlow));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load notifications.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _coralStop, fontSize: 14),
                ),
              ),
            );
          }

          final notifications = _buildNotificationList(snapshot.data ?? []);

          return Column(
            children: [
              // Summary Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cyanGlow.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _cyanGlow.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${notifications.length} UNREAD',
                            style: const TextStyle(
                              color: _cyanGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isApproverRole ? 'Approval Queue' : 'Status Updates',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (notifications.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            for (final item in notifications) {
                              _dismissedIds.add(item.id);
                            }
                          });
                        },
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Notification Feed
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                  color: _cyanGlow,
                  backgroundColor: _cardSurface,
                  onRefresh: () async => _loadNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() => _dismissedIds.add(item.id));
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: _coralStop.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _coralStop.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: _coralStop),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onNavigateToLeaves?.call();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cardSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: item.accentColor.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: item.accentColor.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Glowing Status Icon Badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: item.accentColor.withOpacity(0.35)),
                                  ),
                                  child: Icon(item.icon, color: item.accentColor, size: 22),
                                ),
                                const SizedBox(width: 14),

                                // Notification Body
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: item.accentColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.tag,
                                              style: TextStyle(
                                                color: item.accentColor,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: Colors.white.withOpacity(0.35),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                      ),
                                      if (item.leave.reason.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: _cardElevated,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '"${item.leave.reason}"',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.55),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (item.isActionable) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.touch_app_rounded, size: 14, color: _cyanGlow),
                                            const SizedBox(width: 5),
                                            const Text(
                                              'Tap to review & approve',
                                              style: TextStyle(
                                                color: _cyanGlow,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: _indigoGlow.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Caught Up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isApproverRole
                ? 'No pending team requests waiting for approval.'
                : 'No new leave status updates right now.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final String tag;
  final Color accentColor;
  final IconData icon;
  final LeaveRequest leave;
  final bool isActionable;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.tag,
    required this.accentColor,
    required this.icon,
    required this.leave,
    required this.isActionable,
  });
}