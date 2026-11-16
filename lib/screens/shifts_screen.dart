import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_notifications.dart';

class ShiftsScreen extends StatefulWidget {
  final User user;

  const ShiftsScreen({super.key, required this.user});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  late Future<List<Shift>> _shiftsFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  void _loadShifts() {
    setState(() {
      _shiftsFuture = ApiService.getUserShifts(widget.user.id);
    });
  }

  Future<void> _handleCheckInOut(bool isCurrentlyActive) async {
    setState(() => _isProcessing = true);
    try {
      if (isCurrentlyActive) {
        await ApiService.checkOut(widget.user.id);
        if (!mounted) return;
        AppNotifications.show(context, 'Checked Out', 'Your shift has been completed.');
      } else {
        await ApiService.checkIn(widget.user.id);
        if (!mounted) return;
        AppNotifications.show(context, 'Checked In', 'Your shift is now active.');
      }
      _loadShifts();
    } catch (e) {
      if (!mounted) return;
      AppNotifications.show(
        context,
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02091F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Shifts & Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<Shift>>(
          future: _shiftsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final shifts = snapshot.data ?? [];
            final activeShift = shifts.where((s) => s.status == 'Active').firstOrNull;
            final isCheckedIn = activeShift != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status & Action Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCheckedIn
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isCheckedIn ? Icons.timer : Icons.fingerprint,
                        size: 48,
                        color: isCheckedIn ? Colors.greenAccent : Colors.cyanAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCheckedIn ? 'Shift Active' : 'Ready to Work?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCheckedIn
                            ? 'Checked in at ${_formatTime(activeShift.checkInTime)}'
                            : 'Tap below to start your shift',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handleCheckInOut(isCheckedIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCheckedIn ? Colors.redAccent : Colors.cyanAccent,
                          foregroundColor: isCheckedIn ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          isCheckedIn ? 'Check Out' : 'Check In',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // History Header
                const Text(
                  'Shift History',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // History List
                Expanded(
                  child: shifts.isEmpty
                      ? Center(
                    child: Text(
                      'No shift records yet.',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  )
                      : ListView.builder(
                    itemCount: shifts.length,
                    itemBuilder: (context, index) {
                      final shift = shifts[index];
                      final isActive = shift.status == 'Active';
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(
                            isActive ? Icons.play_circle_fill : Icons.check_circle,
                            color: isActive ? Colors.greenAccent : Colors.cyanAccent,
                          ),
                          title: Text(
                            _formatDate(shift.checkInTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'In: ${_formatTime(shift.checkInTime)}  •  Out: ${shift.checkOutTime != null ? _formatTime(shift.checkOutTime!) : '--:--'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isActive ? Colors.greenAccent : Colors.cyanAccent)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              shift.status,
                              style: TextStyle(
                                color: isActive ? Colors.greenAccent : Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}