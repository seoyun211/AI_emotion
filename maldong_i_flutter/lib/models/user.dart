// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String phone;
  final String userType; // 'senior' or 'guardian'
  final String? email;
  final int? age;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.userType,
    this.email,
    this.age,
  });
}