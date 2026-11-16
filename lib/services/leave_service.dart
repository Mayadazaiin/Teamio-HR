import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/leave_request.dart';

class LeaveService {
  static const String baseUrl = "http://10.0.2.2:5128/api/leaverequests";

  static Future<List<LeaveRequest>> getAccessibleLeaves(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/accessible/$userId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => LeaveRequest.fromJson(item)).toList();
      }
      debugPrint("FETCH FAILED: ${response.statusCode} -> ${response.body}");
      return [];
    } catch (e) {
      debugPrint("Error fetching leaves: $e");
      return [];
    }
  }

  // Returns null on success, or the exact error string on failure
  static Future<String?> submitLeaveRequest({
    required String userId,
    required String type,
    required String dateRange,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      // Send plain dates (no time part) to avoid parsing issues on the API
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      final payload = jsonEncode({
        // sends a number if the id is numeric, otherwise the string as-is
        "userId": int.tryParse(userId) ?? userId,
        "type": type,
        "dateRange": dateRange,
        "startDate": start.toIso8601String(),
        "endDate": end.toIso8601String(),
        "reason": reason,
        "status": "Pending",
      });

      debugPrint("POSTING TO $baseUrl -> $payload");

      final response = await http
          .post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: payload,
      )
          .timeout(const Duration(seconds: 15));

      debugPrint("STATUS: ${response.statusCode} | BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }
      return "Error ${response.statusCode}: ${response.body}";
    } on TimeoutException {
      debugPrint("EXCEPTION: timeout");
      return "Request timed out. Is the API running on port 5128?";
    } catch (e) {
      debugPrint("EXCEPTION: $e");
      return "Connection failed: $e";
    }
  }

  static Future<bool> updateLeaveStatus({
    required String leaveId,
    required String status,
    required String approverId,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/$leaveId/status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status, "approverId": approverId}),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint("UPDATE STATUS: ${response.statusCode} | BODY: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error updating status: $e");
      return false;
    }
  }
}