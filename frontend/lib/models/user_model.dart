class User {
  final int id;
  final String email;
  final String? fullName;
  final String? upiId;
  final String? preferredCurrency;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.upiId,
    this.preferredCurrency,
    required this.createdAt,
  });

  // A factory constructor for creating a new User instance from a map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      upiId: json['upi_id'],
      preferredCurrency: json['preferred_currency'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // A method to check if the profile is considered complete.
  bool get isProfileComplete {
    return fullName != null &&
        fullName!.isNotEmpty &&
        upiId != null &&
        upiId!.isNotEmpty &&
        preferredCurrency != null &&
        preferredCurrency!.isNotEmpty;
  }
}
