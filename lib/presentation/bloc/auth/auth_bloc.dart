import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/otp_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final StorageRepository _storageRepository;
  final OtpRepository _otpRepository;

  
  Map<String, dynamic>? _pendingSignUpData;
  Map<String, dynamic>? _pendingSignInData;

  AuthBloc({
    required AuthRepository authRepository,
    required StorageRepository storageRepository,
    required OtpRepository otpRepository,
  }) : _authRepository = authRepository,
       _storageRepository = storageRepository,
       _otpRepository = otpRepository,
       super(AuthInitialState()) {
    on<CheckSessionEvent>(_onCheckSession);
    on<SignUpRequestedEvent>(_onSignUpRequested);
    on<SignInRequestedEvent>(_onSignInRequested);
    on<SendOtpEvent>(_onSendOtp);
    on<OtpVerificationRequestedEvent>(_onOtpVerificationRequested);
    on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
    on<SignOutRequestedEvent>(_onSignOutRequested);
    on<DeleteAccountRequestedEvent>(_onDeleteAccountRequested);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }


  Future<void> _onCheckSession(
    CheckSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());

      final isLoggedIn = await _storageRepository.isLoggedIn();

      if (isLoggedIn) {
        final userId = await _storageRepository.getUserId();
        if (userId != null) {
          final user = await _authRepository.getUserData(userId);
          if (user != null) {
            emit(AuthenticatedState(user));
            return;
          }
        }
      }

      emit(UnauthenticatedState());
    } catch (e) {
      emit(UnauthenticatedState());
    }
  }


  Future<void> _onSignUpRequested(
    SignUpRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());


      _pendingSignUpData = {
        'email': event.email,
        'password': event.password,
        'name': event.name,
        'profileImagePath': event.profileImagePath,
      };


      final success = await _otpRepository.sendOtp(event.email);

      if (success) {
        emit(OtpSentState(email: event.email, isSignUp: true));
      } else {
        emit(const AuthErrorState('Failed to send OTP. Please try again.'));
      }
    } catch (e) {
      emit(AuthErrorState('Error: ${e.toString()}'));
    }
  }

  
  Future<void> _onSignInRequested(
    SignInRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());


      try {
        final userCredential = await _authRepository.signIn(
          email: event.email,
          password: event.password,
        );

        if (userCredential == null) {
          emit(const AuthErrorState('Invalid credentials'));
          return;
        }

        await _authRepository.signOut();

    
        _pendingSignInData = {'email': event.email, 'password': event.password};

        final success = await _otpRepository.sendOtp(event.email);

        if (success) {
          emit(OtpSentState(email: event.email, isSignUp: false));
        } else {
          emit(const AuthErrorState('Failed to send OTP. Please try again.'));
        }
      } catch (e) {
 
        emit(AuthErrorState(e.toString()));
      }
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  
  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoadingState());

      final success = await _otpRepository.sendOtp(event.email);

      if (success) {
        
        final isSignUp = _pendingSignUpData != null;
        emit(OtpSentState(email: event.email, isSignUp: isSignUp));
      } else {
        emit(const AuthErrorState('Failed to send OTP. Please try again.'));
      }
    } catch (e) {
      emit(AuthErrorState('Error: ${e.toString()}'));
    }
  }

  Future<void> _onOtpVerificationRequested(
    OtpVerificationRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());

 
      final isValid = _otpRepository.verifyOtp(event.email, event.otp);

      if (!isValid) {
        emit(const AuthErrorState('Invalid or expired OTP. Please try again.'));
        return;
      }

      if (event.isSignUp) {

        if (_pendingSignUpData == null) {
          emit(
            const AuthErrorState('Signup data not found. Please try again.'),
          );
          return;
        }

        final user = await _authRepository.signUp(
          email: _pendingSignUpData!['email'],
          password: _pendingSignUpData!['password'],
          name: _pendingSignUpData!['name'],
        );

        if (user != null) {
         
          await _storageRepository.saveSession(
            userId: user.id,
            userEmail: user.email,
          );

          _pendingSignUpData = null;
          emit(AuthenticatedState(user));
        } else {
          emit(
            const AuthErrorState('Failed to create account. Please try again.'),
          );
        }
      } else {
        
        if (_pendingSignInData == null) {
          emit(const AuthErrorState('Login data not found. Please try again.'));
          return;
        }

       
        final user = await _authRepository.signIn(
          email: _pendingSignInData!['email'],
          password: _pendingSignInData!['password'],
        );

        if (user != null) {
        
          await _storageRepository.saveSession(
            userId: user.id,
            userEmail: user.email,
            profileImagePath: user.profileImageUrl,
          );

          _pendingSignInData = null;
          emit(AuthenticatedState(user));
        } else {
          emit(const AuthErrorState('Failed to sign in. Please try again.'));
        }
      }
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());

      await _authRepository.sendPasswordResetEmail(event.email);

      emit(AuthSuccessState('Password reset link sent to ${event.email}'));
    } catch (e) {
      emit(AuthErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  
  Future<void> _onSignOutRequested(
    SignOutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());

      await _authRepository.signOut();
      await _storageRepository.clearSession();

      emit(UnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState('Failed to sign out: ${e.toString()}'));
    }
  }

  
  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());

      await _authRepository.deleteAccount(event.userId);
      await _storageRepository.clearSession();

      emit(UnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState('Failed to delete account: ${e.toString()}'));
    }
  }

  
  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoadingState());

      if (event.profileImagePath != null) {
        await _storageRepository.saveProfileImagePath(event.profileImagePath!);
      }

      await _authRepository.updateUserProfile(
        userId: event.userId,
        name: event.name,
        profileImagePath: event.profileImagePath,
      );

      final updatedUser = await _authRepository.getUserData(event.userId);

      if (updatedUser != null) {
        emit(AuthenticatedState(updatedUser));
      } else {
        emit(const AuthErrorState('Failed to load updated profile.'));
      }
    } catch (e) {
      emit(AuthErrorState('Failed to update profile: ${e.toString()}'));
    }
  }
}
