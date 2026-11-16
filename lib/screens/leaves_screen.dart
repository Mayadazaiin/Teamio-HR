import 'package:flutter/material.dart';
import 'package:teamio_hr/models/leave_request.dart';
import 'package:teamio_hr/screens/submit_leave_screen.dart';
import 'package:teamio_hr/services/leave_service.dart';

class LeavesScreen extends StatefulWidget {
  final dynamic user;

  const LeavesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  late Future<List<LeaveRequest>> _futureLeaves;
  String _selectedFilter = 'All';

  // Unified Executive SaaS Palette
  static const Color bgDark = Color(0xFF060913);
  static const Color cardDark = Color(0xFF111729);
  static const Color surfaceDark = Color(0xFF182038);
  static const Color accentPrimary = Color(0xFF38BDF8);
  static const Color accentSecondary = Color(0xFF818CF8);
  static const Color accentCasual = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  // Default annual quotas
  static const int _initialAnnualQuota = 15;
  static const int _initialSickQuota = 7;
  static const int _initialCasualQuota = 6;

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

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    setState(() {
      _futureLeaves = LeaveService.getAccessibleLeaves(_currentUserId);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return successGreen;
      case 'rejected':
        return dangerRed;
      default:
        return accentCasual;
    }
  }

  /// Calculates inclusive leave days from startDate/endDate if available,
  /// otherwise parses dateRange (e.g. "Nov 23, 2026 - Nov 25, 2026" -> 3 days).
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
    } catch (_) {
      // Fallback to parsing dateRange string below
    }

    try {
      final range = leave.dateRange;
      final parts = range.split(RegExp(r'\s*[-–—]\s*'));
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

  Future<void> _handleStatusUpdate(String leaveId, String newStatus) async {
    bool success = await LeaveService.updateLeaveStatus(
      leaveId: leaveId,
      status: newStatus,
      approverId: _currentUserId,
    );

    if (!mounted) return;
    if (success) {
      _loadLeaves();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text("Request marked as $newStatus", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: dangerRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Text("Could not update status."),
        ),
      );
    }
  }

  Future<void> _navigateToSubmit() async {
    final bool? submitted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitLeaveScreen(user: widget.user),
      ),
    );

    if (submitted == true) {
      _loadLeaves();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          "Time Off",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        ),
        backgroundColor: bgDark,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: accentPrimary, size: 20),
              onPressed: _loadLeaves,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveRequest>>(
        future: _futureLeaves,
        builder: (context, snapshot) {
          final allLeaves = snapshot.data ?? [];

          // Calculate dynamic balances for the logged-in user's approved leaves
          int usedAnnual = 0;
          int usedSick = 0;
          int usedCasual = 0;

          for (final leave in allLeaves) {
            if (leave.userId.toLowerCase() == _currentUserId.toLowerCase() &&
                leave.status.toLowerCase() == 'approved') {
              final days = _calculateLeaveDays(leave);
              final type = leave.type.toLowerCase();
              if (type.contains('annual')) {
                usedAnnual += days;
              } else if (type.contains('sick')) {
                usedSick += days;
              } else if (type.contains('casual')) {
                usedCasual += days;
              }
            }
          }

          final remainingAnnual = (_initialAnnualQuota - usedAnnual).clamp(0, _initialAnnualQuota);
          final remainingSick = (_initialSickQuota - usedSick).clamp(0, _initialSickQuota);
          final remainingCasual = (_initialCasualQuota - usedCasual).clamp(0, _initialCasualQuota);

          var filteredLeaves = allLeaves;
          if (_selectedFilter != 'All') {
            filteredLeaves = allLeaves
                .where((l) => l.status.toLowerCase() == _selectedFilter.toLowerCase())
                .toList();
          }

          return Column(
            children: [
              // Top 3 Balance Summary Cards (Annual, Sick, Casual)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    _buildBalanceCard("Annual", "$remainingAnnual", "Days Left", accentPrimary, Icons.wb_sunny_rounded),
                    const SizedBox(width: 10),
                    _buildBalanceCard("Sick", "$remainingSick", "Days Left", accentSecondary, Icons.favorite_rounded),
                    const SizedBox(width: 10),
                    _buildBalanceCard("Casual", "$remainingCasual", "Days Left", accentCasual, Icons.coffee_rounded),
                  ],
                ),
              ),

              // Filter Tabs
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'Pending', 'Approved', 'Rejected'].map((filter) {
                    bool isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? accentPrimary : cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? accentPrimary : Colors.white10),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? bgDark : Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Leave Requests Feed
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator(color: accentPrimary))
                    : snapshot.hasError
                    ? Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
                    : filteredLeaves.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 150),
                  itemCount: filteredLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = filteredLeaves[index];
                    final statusColor = _getStatusColor(leave.status);
                    final daysCount = _calculateLeaveDays(leave);

                    bool isManagerRole = ['senior', 'team lead', 'team leader', 'hr', 'manager']
                        .contains(_currentUserRole.trim().toLowerCase());
                    bool canApprove = isManagerRole &&
                        (leave.userId.toLowerCase() != _currentUserId.toLowerCase()) &&
                        (leave.status.toLowerCase() == 'pending');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 19,
                                    backgroundColor: accentPrimary.withOpacity(0.15),
                                    child: Text(
                                      leave.employeeName.isNotEmpty
                                          ? leave.employeeName[0].toUpperCase()
                                          : "U",
                                      style: const TextStyle(
                                        color: accentPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        leave.employeeName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        "${leave.type} • $daysCount ${daysCount == 1 ? 'day' : 'days'}",
                                        style: const TextStyle(
                                          color: accentPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  leave.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surfaceDark,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.white54),
                                    const SizedBox(width: 8),
                                    Text(
                                      leave.dateRange,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (leave.reason.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes_rounded, size: 15, color: Colors.white54),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          leave.reason,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (canApprove) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: dangerRed,
                                      side: const BorderSide(color: dangerRed),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _handleStatusUpdate(leave.id, 'Rejected'),
                                    child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: successGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _handleStatusUpdate(leave.id, 'Approved'),
                                    child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton.extended(
          backgroundColor: accentPrimary,
          foregroundColor: bgDark,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text("New Request", style: TextStyle(fontWeight: FontWeight.w800)),
          onPressed: _navigateToSubmit,
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, String count, String unit, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 17),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    unit,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 52, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            "No $_selectedFilter requests",
            style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}