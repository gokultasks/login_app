//AppConstants.dart

class AppConstants {
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
 
  static const String senderEmail = 'xxxx@gmail.com';
  static const String appPassword = 'xxxxxx';

  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserId = 'userId';
  static const String keyUserEmail = 'userEmail';
  static const String keyProfileImagePath = 'profileImagePath';

  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';

  static const int otpLength = 6;
  static const int otpValidityMinutes = 10;
}
