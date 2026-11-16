class LeaveRequest {
  final String id;
  final String userId;
  final String employeeName;
  final String employeeLevel;
  final String type;
  final String dateRange;
  final String reason;
  String status;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.employeeLevel,
    required this.type,
    required this.dateRange,
    required this.reason,
    required this.status,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? 'Employee',
      employeeLevel: json['employeeLevel']?.toString() ?? 'Junior',
      type: json['type']?.toString() ?? 'Annual Leave',
      dateRange: json['dateRange']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
    );
  }
}