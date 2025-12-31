class OtpModel {
  final String otp;
  final DateTime expiryTime;
  final String email;

  OtpModel({required this.otp, required this.expiryTime, required this.email});

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
