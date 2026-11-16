import 'package:flutter/material.dart';
import 'package:teamio_hr/models/leave_request.dart';
import 'package:teamio_hr/services/leave_service.dart';
import 'submit_leave_screen.dart'; // We'll create this next

class LeaveDashboardScreen extends StatefulWidget {
  final String currentUserId; // Pass the logged-in user's ID here

  const LeaveDashboardScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _LeaveDashboardScreenState createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen> {
  late Future<List<LeaveRequest>> _futureLeaves;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    setState(() {
      _futureLeaves = LeaveService.getAccessibleLeaves(widget.currentUserId);
    });
  }

  // Helper color for status badges
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave Management"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaves,
          ),
        ],
      ),
      body: FutureBuilder<List<LeaveRequest>>(
        future: _futureLeaves,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No leave requests found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final leaves = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            leave.employeeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(leave.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(leave.status)),
                            ),
                            child: Text(
                              leave.status,
                              style: TextStyle(
                                color: _getStatusColor(leave.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Level: ${leave.employeeLevel}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text("Type: ${leave.type}", style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 16, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(leave.dateRange),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Reason: ${leave.reason}",
                              style: const TextStyle(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Request Leave"),
        onPressed: () async {
          // Navigate to Submit Form
          final submitted = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitLeaveScreen(user: widget.currentUserId),
            ),
          );
          if (submitted == true) {
            _loadLeaves(); // Refresh list after submitting
          }
        },
      ),
    );
  }
}