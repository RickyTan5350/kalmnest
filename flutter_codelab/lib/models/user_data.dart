class UserData {
  final String email;
  final String name;
  final String? phone_no;
  final String? address;
  final String? gender;
  final String password;
  final String passwordConfirmation;
  final bool accountStatus;
  final String roleName;

  UserData({
    required this.email,
    required this.name,
    this.phone_no,
    this.address,
    this.gender,
    required this.password,
    required this.passwordConfirmation,
    required this.accountStatus,
    required this.roleName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone_no': phone_no,
      'address': address,
      'gender': gender,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role_name': roleName,
    };
  }

  bool get isStudent => roleName.toLowerCase() == 'student';
}

// --- NEW CLASS FOR USER LIST DISPLAY ---
class UserListItem {
  final String id;
  final String name;
  final String email;
  final String roleName;
  final String accountStatus;

  UserListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    required this.accountStatus,
  });

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      id: json['user_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      // LOGIC UPDATE: Safely access nested role object
      roleName: (json['role'] != null && json['role'] is Map && json['role']['role_name'] != null)
          ? json['role']['role_name'].toString()
          : 'N/A',
      accountStatus: json['account_status'] ?? 'unknown',
    );
  }
}


class UserDetails {
  final String id;
  final String name;
  final String email;
  final String phoneNo;
  final String address;
  final String gender;
  final String accountStatus;
  final String roleName;
  final String joinedDate;
  final String token;

  UserDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNo,
    required this.address,
    required this.gender,
    required this.accountStatus,
    required this.roleName,
    required this.joinedDate,
    this.token = '',
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['user_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phoneNo: json['phone_no'] ?? 'N/A',
      address: json['address'] ?? 'N/A',
      gender: json['gender'] ?? 'N/A',
      accountStatus: json['account_status'] ?? 'unknown',

      // LOGIC UPDATE: Handle the nested 'role' object from Laravel
      roleName: (json['role'] != null && json['role'] is Map && json['role']['role_name'] != null)
          ? json['role']['role_name'].toString()
          : 'N/A',

      joinedDate: json['created_at'] ?? '',
      token: '',
    );
  }

  // Convenience getter to return a role object-like interface for compatibility
  UserRole? get role => UserRole(roleName: roleName);

  bool get isStudent => roleName.trim().toLowerCase() == 'student';
  bool get isAdmin => roleName.trim().toLowerCase() == 'admin';
  bool get isTeacher => roleName.trim().toLowerCase() == 'teacher';

  // Copy with method to create a new instance with optional field updates
  UserDetails copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNo,
    String? address,
    String? gender,
    String? accountStatus,
    String? roleName,
    String? joinedDate,
    String? token,
  }) {
    return UserDetails(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      accountStatus: accountStatus ?? this.accountStatus,
      roleName: roleName ?? this.roleName,
      joinedDate: joinedDate ?? this.joinedDate,
      token: token ?? this.token,
    );
  }
}

// Simple role class for compatibility with FeedbackPage
class UserRole {
  final String roleName;
  UserRole({required this.roleName});
}