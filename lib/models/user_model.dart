// models/user_model.dart
class User {
  final int id;
  final String name;
  final String email;
  final String shopName;
  final String? emailVerifiedAt;
  final String role;
  final String address;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.shopName,
    this.emailVerifiedAt,
    required this.role,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      shopName: json['shop_name'] ?? '',
      emailVerifiedAt: json['email_verified_at']?? '',
      role: json['role']?? '',
      address: json['address']?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': shopName,
      'email_verified_at': emailVerifiedAt,
      'role': role,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}