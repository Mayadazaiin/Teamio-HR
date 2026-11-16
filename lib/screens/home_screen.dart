import 'package:flutter/material.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';
import '../services/leave_service.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  final VoidCallback onNavigateToLeaves;
  final VoidCallback onNavigateToProfile;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onNavigateToLeaves,
    required this.onNavigateToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Unified Executive SaaS Palette (matches DashboardScreen)
  static const Color _bgCanvas = Color(0xFF060913);
  static const Color _cardSurface = Color(0xFF111729);
  static const Color _cardElevated = Color(0xFF182038);
  static const Color _cyanGlow = Color(0xFF38BDF8);
  static const Color _indigoGlow = Color(0xFF818CF8);
  static const Color _emeraldLive = Color(0xFF10B981);
  static const Color _amberWarn = Color(0xFFF59E0B);
  static const Color _coralStop = Color(0xFFF43F5E);

  static const int _initialAnnualQuota = 15;

  bool _isCheckedIn = false;
  String _checkInTimeText = 'Not checked in today';
  bool _isLoading = false;

  int _remainingAnnualDays = _initialAnnualQuota;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadLeaveSummary();
  }

  String get _currentUserRole {
    try {
      final dynamic u = widget.user;
      final role = (u is Map ? u['role'] : u.role)?.toString().toLowerCase() ?? '';
      final level = (u is Map ? u['level'] : u.level)?.toString().toLowerCase() ?? '';
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

  Future<void> _loadLeaveSummary() async {
    try {
      final userId = widget.user.id.toString();
      final leaves = await LeaveService.getAccessibleLeaves(userId);

      int usedAnnual = 0;
      bool unread = false;

      for (final leave in leaves) {
        final isOwn = leave.userId.toLowerCase() == userId.toLowerCase();
        final status = leave.status.trim().toLowerCase();

        if (isOwn && status == 'approved' && leave.type.toLowerCase().contains('annual')) {
          usedAnnual += _calculateLeaveDays(leave);
        }

        if (_isApproverRole && !isOwn && status == 'pending') {
          unread = true;
        } else if (isOwn && (status == 'approved' || status == 'rejected')) {
          unread = true;
        }
      }

      if (!mounted) return;
      setState(() {
        _remainingAnnualDays = (_initialAnnualQuota - usedAnnual).clamp(0, _initialAnnualQuota);
        _hasUnreadNotifications = unread;
      });
    } catch (_) {
      // Keep default quota if offline
    }
  }

  int _calculateLeaveDays(LeaveRequest leave) {
    try {
      final dynamic dyn = leave;
      if (dyn.startDate != null && dyn.endDate != null) {
        final DateTime start = dyn.startDate is DateTime
            ? dyn.startDate
            : DateTime.parse(dyn.startDate.toString());
        final DateTime end = dyn.endDate is DateTime
            ? dyn.endDate
            : DateTime.parse(dyn.endDate.toString());
        final diff = DateTime(end.year, end.month, end.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays +
            1;
        if (diff > 0) return diff;
      }
    } catch (_) {}

    try {
      final parts = leave.dateRange.split(RegExp(r'\s*[-–—]\s*'));
      if (parts.length == 2) {
        final start = _parseFlexibleDate(parts[0].trim());
        final end = _parseFlexibleDate(parts[1].trim(), fallbackYear: start?.year);
        if (start != null && end != null) {
          final diff = end.difference(start).inDays + 1;
          if (diff > 0) return diff;
        }
      }
    } catch (_) {}

    return 1;
  }

  DateTime? _parseFlexibleDate(String text, {int? fallbackYear}) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final match = RegExp(r'([A-Za-z]+)\s+(\d{1,2})(?:,?\s*(\d{4}))?').firstMatch(text);
    if (match != null) {
      final mStr = match.group(1)!.toLowerCase();
      final mKey = mStr.length >= 3 ? mStr.substring(0, 3) : mStr;
      final month = months[mKey];
      final day = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3) ?? '') ?? fallbackYear ?? DateTime.now().year;
      if (month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(text);
  }

  void _toggleCheckIn() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isCheckedIn = !_isCheckedIn;
        if (_isCheckedIn) {
          final now = TimeOfDay.now();
          _checkInTimeText = 'Checked in at ${now.format(context)}';
        } else {
          _checkInTimeText = 'Shift completed • Checked out';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isCheckedIn ? Icons.bolt_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _isCheckedIn ? 'Successfully checked in!' : 'Checked out for the day.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: _isCheckedIn ? _emeraldLive : _cyanGlow,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    });
  }

  String _formattedToday() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.email;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';
    final statusColor = _isCheckedIn ? _emeraldLive : _amberWarn;

    return Container(
      color: _bgCanvas,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _cyanGlow,
          backgroundColor: _cardSurface,
          onRefresh: _loadLeaveSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Executive Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_cyanGlow, _indigoGlow],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: _cardSurface,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formattedToday().toUpperCase(),
                                  style: TextStyle(
                                    color: _cyanGlow.withOpacity(0.85),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Glass Notification Button with Dynamic Dot
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationsScreen(
                                    user: widget.user,
                                    onNavigateToLeaves: widget.onNavigateToLeaves,
                                  ),
                                ),
                              );
                              _loadLeaveSummary();
                            },
                          ),
                        ),
                        if (_hasUnreadNotifications)
                          Positioned(
                            right: 11,
                            top: 11,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _cyanGlow,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: _cyanGlow.withOpacity(0.8), blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Luminous Hero Attendance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isCheckedIn
                          ? [const Color(0xFF0E2926), const Color(0xFF0D1526)]
                          : [const Color(0xFF141E36), const Color(0xFF0C1222)],
                    ),
                    border: Border.all(
                      color: (_isCheckedIn ? _emeraldLive : _cyanGlow).withOpacity(0.32),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isCheckedIn ? _emeraldLive : _cyanGlow).withOpacity(0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fingerprint_rounded,
                                size: 16,
                                color: _isCheckedIn ? _emeraldLive : _cyanGlow,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'TODAY\'S ATTENDANCE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: statusColor, blurRadius: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isCheckedIn ? 'ACTIVE SHIFT' : 'STANDBY',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _checkInTimeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCheckedIn
                            ? 'Your live work session is currently being tracked'
                            : 'Punch in to begin recording your daily work hours',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Gradient Action Button
                      GestureDetector(
                        onTap: _isLoading ? null : _toggleCheckIn,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: _isCheckedIn
                                  ? [const Color(0xFFF43F5E), const Color(0xFFE11D48)]
                                  : [const Color(0xFF38BDF8), const Color(0xFF6366F1)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isCheckedIn ? _coralStop : _cyanGlow).withOpacity(0.32),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCheckedIn ? 'Check Out Now' : 'Check In Now',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Dynamic Bento Snapshot Strip
                Row(
                  children: [
                    _buildStatTile(
                      title: 'Annual Leave',
                      value: '$_remainingAnnualDays ${_remainingAnnualDays == 1 ? 'Day' : 'Days'}',
                      subtitle: 'Available balance',
                      icon: Icons.wb_sunny_rounded,
                      accent: _cyanGlow,
                      onTap: widget.onNavigateToLeaves,
                    ),
                    const SizedBox(width: 12),
                    _buildStatTile(
                      title: 'Daily Target',
                      value: '8h 00m',
                      subtitle: 'Standard schedule',
                      icon: Icons.timelapse_rounded,
                      accent: _indigoGlow,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // 4. Quick Actions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Workspace',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildActionCard(
                      icon: Icons.event_note_rounded,
                      label: 'Request Leave',
                      color: _cyanGlow,
                      onTap: widget.onNavigateToLeaves,
                    ),
                    const SizedBox(width: 10),
                    _buildActionCard(
                      icon: Icons.history_rounded,
                      label: 'Leave History',
                      color: _emeraldLive,
                      onTap: widget.onNavigateToLeaves,
                    ),
                    const SizedBox(width: 10),
                    _buildActionCard(
                      icon: Icons.badge_rounded,
                      label: 'My Profile',
                      color: _amberWarn,
                      onTap: widget.onNavigateToProfile,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 5. Featured Company Announcement Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_cyanGlow.withOpacity(0.2), _indigoGlow.withOpacity(0.2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cyanGlow.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: _cyanGlow, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _indigoGlow.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'POLICY UPDATE',
                                    style: TextStyle(
                                      color: _indigoGlow,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Hybrid & Remote Guidelines',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Updated flexible work schedules are now live in your HR handbook.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.28)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}