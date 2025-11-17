// lib/models/user_models.dart
class UserCreateRequest {
  final String username;
  final String gender;
  final String birthDate; // "YYYY-MM-DD"
  final String address;
  final String guardianName;
  final String guardianPhone;

  UserCreateRequest({
    required this.username,
    required this.gender,
    required this.birthDate,
    required this.address,
    required this.guardianName,
    required this.guardianPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "gender": gender,
      "birth_date": birthDate,
      "address": address,
      "guardian_name": guardianName,
      "guardian_phone": guardianPhone,
    };
  }
}

class UserResponse {
  final int userId;
  final String username;
  final String gender;
  final String birthDate;
  final String address;
  final String guardianName;
  final String guardianPhone;
  final String createdAt;

  UserResponse({
    required this.userId,
    required this.username,
    required this.gender,
    required this.birthDate,
    required this.address,
    required this.guardianName,
    required this.guardianPhone,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      gender: json['gender'] as String,
      birthDate: json['birth_date'] as String,
      address: json['address'] as String,
      guardianName: json['guardian_name'] as String,
      guardianPhone: json['guardian_phone'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
