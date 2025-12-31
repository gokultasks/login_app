import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/otp_model.dart';
import '../../core/constants/app_constants.dart';

class OtpRepository {
  
  final Map<String, OtpModel> _otpStorage = {};

  
  String _generateOtp() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < AppConstants.otpLength; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  
  Future<bool> sendOtp(String email) async {
    try {
      final otp = _generateOtp();
      final expiryTime = DateTime.now().add(
        Duration(minutes: AppConstants.otpValidityMinutes),
      );

  
      _otpStorage[email] = OtpModel(
        otp: otp,
        expiryTime: expiryTime,
        email: email,
      );

      
      final smtpServer = gmail(
        AppConstants.senderEmail,
        AppConstants.appPassword,
      );

      
      final message = Message()
        ..from = Address(AppConstants.senderEmail, 'Login App')
        ..recipients.add(email)
        ..subject = 'Your OTP Code'
        ..html =
            '''
          <h2>Your OTP Code</h2>
          <p>Your one-time password is: <strong style="font-size: 24px;">$otp</strong></p>
          <p>This OTP is valid for ${AppConstants.otpValidityMinutes} minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
        ''';

      
      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  
  bool verifyOtp(String email, String otp) {
    final storedOtp = _otpStorage[email];

    if (storedOtp == null) {
      return false;
    }

    if (storedOtp.isExpired) {
      _otpStorage.remove(email);
      return false;
    }

    if (storedOtp.otp == otp) {
      _otpStorage.remove(email);
      return true;
    }

    return false;
  }

  
  void clearOtp(String email) {
    _otpStorage.remove(email);
  }
}
