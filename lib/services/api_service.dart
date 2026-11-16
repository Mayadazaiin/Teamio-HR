import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? level;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.level,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      role: json['role'] ?? json['Role'] ?? 'employee',
      level: json['level'] ?? json['Level'],
    );
  }
}

class Shift {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;

  Shift({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      checkInTime: DateTime.parse(json['checkInTime'] ?? json['CheckInTime']).toLocal(),
      checkOutTime: (json['checkOutTime'] ?? json['CheckOutTime']) != null
          ? DateTime.parse(json['checkOutTime'] ?? json['CheckOutTime']).toLocal()
          : null,
      status: json['status'] ?? json['Status'] ?? 'Active',
    );
  }
}

class ApiService {
  // Verify this matches the port your C# API terminal outputs when starting up (e.g. 5128)
  static const String baseUrl = 'http://10.0.2.2:5128/api';

  static String _extractError(http.Response response) {
    if (response.body.isEmpty) {
      return 'Server returned status ${response.statusCode} with an empty body.';
    }
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map) {
        if (errorData.containsKey('message')) {
          return errorData['message'].toString();
        }
        if (errorData.containsKey('title')) {
          return errorData['title'].toString();
        }
      }
      return response.body;
    } catch (_) {
      return response.body;
    }
  }

  static Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) throw Exception('Server returned an empty response.');
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server. Ensure your C# API is running.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<User> signup({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? level,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
          'level': level,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) throw Exception('Server returned an empty response.');
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server. Ensure your C# API is running.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<List<Shift>> getUserShifts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shifts/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Iterable list = jsonDecode(response.body);
        return list.map((model) => Shift.fromJson(model)).toList();
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Shift> checkIn(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shifts/checkin/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Shift.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Shift> checkOut(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shifts/checkout/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Shift.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<List<dynamic>> getUserLeaves(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaves/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
  static Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'CurrentPassword': currentPassword, // Covers PascalCase C# DTOs
          'newPassword': newPassword,
          'NewPassword': newPassword,         // Covers PascalCase C# DTOs
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
  // Updated to handle Multipart Form Data for uploading name and profile image
  static Future<void> updateUserProfile(String userId, String fullName, File? imageFile) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/$userId'));

      // Send fullName field
      request.fields['fullName'] = fullName;

      // Attach image if user selected one
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', imageFile.path),
        );
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(_extractError(response));
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> createLeaveRequest(String userId, String type, String dateRange) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leaves/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'type': type,
          'dateRange': dateRange,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? response.body;
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}