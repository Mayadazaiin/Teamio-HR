import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'leaves_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _bgCanvas = Color(0xFF060913);
  static const Color _cardSurface = Color(0xFF111729);
  static const Color _cardElevated = Color(0xFF182038);
  static const Color _cyanGlow = Color(0xFF38BDF8);
  static const Color _indigoGlow = Color(0xFF818CF8);
  static const Color _emeraldLive = Color(0xFF10B981);
  static const Color _coralStop = Color(0xFFF43F5E);

  List<Shift> _shifts = [];
  bool _isLoadingShifts = true;
  bool _isCheckingAction = false;
  int _selectedIndex = 0;

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Shift? get _activeShift {
    try {
      return _shifts.firstWhere((s) => s.checkOutTime == null);
    } catch (_) {
      return null;
    }
  }

  void _startOrStopTimer() {
    _timer?.cancel();
    final active = _activeShift;

    if (active != null) {
      _elapsed = DateTime.now().difference(active.checkInTime.toLocal());
      if (_elapsed.isNegative) _elapsed = Duration.zero;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(active.checkInTime.toLocal());
          if (_elapsed.isNegative) _elapsed = Duration.zero;
        });
      });
    } else {
      setState(() {
        _elapsed = Duration.zero;
      });
    }
  }

  Future<void> _fetchShifts() async {
    try {
      List<Shift> shifts = await ApiService.getUserShifts(widget.user.id);
      shifts.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      if (!mounted) return;
      setState(() {
        _shifts = shifts;
        _isLoadingShifts = false;
      });
      _startOrStopTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingShifts = false);
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingAction = true);
    try {
      await ApiService.checkIn(widget.user.id);
      await _fetchShifts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Shift started — have a productive day!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _emeraldLive,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _coralStop,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingAction = false);
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isCheckingAction = true);
    try {
      await ApiService.checkOut(widget.user.id);
      await _fetchShifts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Shift logged & closed!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _cyanGlow,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _coralStop,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingAction = false);
    }
  }

  String _formatTimer(Duration d) {
    if (d.isNegative) return '00:00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[localDt.weekday - 1]}, ${months[localDt.month - 1]} ${localDt.day}';
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour % 12 == 0 ? 12 : localDt.hour % 12;
    final minute = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDurationBadge(Shift shift) {
    if (shift.checkOutTime == null) return 'LIVE';
    final diff = shift.checkOutTime!.toLocal().difference(shift.checkInTime.toLocal());
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  Widget _buildShiftsTab() {
    final active = _activeShift;
    final isShiftActive = active != null;
    final themeColor = isShiftActive ? _emeraldLive : _cyanGlow;
    final double ringProgress = isShiftActive
        ? (_elapsed.inSeconds / 28800).clamp(0.04, 1.0)
        : 0.0;

    return RefreshIndicator(
      color: _cyanGlow,
      backgroundColor: _cardSurface,
      onRefresh: _fetchShifts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(DateTime.now()).toUpperCase(),
                        style: TextStyle(
                          color: _cyanGlow.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Shift Tracker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: themeColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: themeColor, blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isShiftActive ? 'ACTIVE' : 'OFFLINE',
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isShiftActive
                        ? [const Color(0xFF0E2926), const Color(0xFF0D1526)]
                        : [const Color(0xFF141E36), const Color(0xFF0C1222)],
                  ),
                  border: Border.all(
                    color: themeColor.withOpacity(0.3),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 196,
                      height: 196,
                      child: CustomPaint(
                        painter: _ShiftRingPainter(
                          progress: ringProgress,
                          activeColor: themeColor,
                          trackColor: Colors.white.withOpacity(0.07),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isShiftActive ? 'ELAPSED' : 'READY',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTimer(_elapsed),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isShiftActive ? 'Goal: 8h 00m' : 'Tap below to start',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          _buildMiniStat(
                            'Clock In',
                            isShiftActive ? _formatTime(active.checkInTime) : '--:--',
                            Icons.login_rounded,
                            _cyanGlow,
                          ),
                          _buildVerticalDivider(),
                          _buildMiniStat(
                            'Total Logs',
                            '${_shifts.length}',
                            Icons.layers_rounded,
                            _indigoGlow,
                          ),
                          _buildVerticalDivider(),
                          _buildMiniStat(
                            'Status',
                            isShiftActive ? 'Working' : 'Idle',
                            Icons.bolt_rounded,
                            themeColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _isCheckingAction
                          ? null
                          : (isShiftActive ? _handleCheckOut : _handleCheckIn),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: isShiftActive
                                ? [const Color(0xFFF43F5E), const Color(0xFFE11D48)]
                                : [const Color(0xFF38BDF8), const Color(0xFF6366F1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isShiftActive ? _coralStop : _cyanGlow).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isCheckingAction
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isShiftActive ? Icons.stop_circle_outlined : Icons.fingerprint_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isShiftActive ? 'End Shift & Check Out' : 'Punch In Now',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
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
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attendance Timeline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Pull to sync',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoadingShifts)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: _cyanGlow)),
            )
          else if (_shifts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No shift records found yet.',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final shift = _shifts[index];
                    final isCurrent = shift.checkOutTime == null;
                    final isLast = index == _shifts.length - 1;
                    final nodeColor = isCurrent ? _emeraldLive : _cyanGlow;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 18),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: nodeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _bgCanvas, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: nodeColor.withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cardSurface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isCurrent
                                      ? _emeraldLive.withOpacity(0.35)
                                      : Colors.white.withOpacity(0.07),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(shift.checkInTime),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule_rounded, size: 13, color: Colors.white.withOpacity(0.45)),
                                          const SizedBox(width: 5),
                                          Text(
                                            shift.checkOutTime != null
                                                ? '${_formatTime(shift.checkInTime)} — ${_formatTime(shift.checkOutTime!)}'
                                                : '${_formatTime(shift.checkInTime)} — Active',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: nodeColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: nodeColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _formatDurationBadge(shift),
                                      style: TextStyle(
                                        color: nodeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _shifts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        user: widget.user,
        onNavigateToLeaves: () => setState(() => _selectedIndex = 2),
        onNavigateToProfile: () => setState(() => _selectedIndex = 3),
      ),
      _buildShiftsTab(),
      LeavesScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _cardElevated.withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home'),
              _buildNavItem(1, Icons.access_time_outlined, Icons.access_time_filled_rounded, 'Shifts'),
              _buildNavItem(2, Icons.event_available_outlined, Icons.event_available_rounded, 'Leaves'),
              _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _cyanGlow.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? _cyanGlow : Colors.white.withOpacity(0.5),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _cyanGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShiftRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _ShiftRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final glowPaint = Paint()
        ..color = activeColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final progressPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShiftRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
}