class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? department;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      department: json['department'],
    );
  }
}