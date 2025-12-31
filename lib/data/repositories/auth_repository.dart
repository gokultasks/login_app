import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  
  User? get currentUser => _firebaseAuth.currentUser;

  

  
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        profileImageUrl: null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      return await getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? profileImagePath,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
      }

      if (profileImagePath != null) {
        
        updates['profileImageUrl'] = profileImagePath;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  
  Future<void> deleteAccount(String userId) async {
    try {
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();


      await _firebaseAuth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }


  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
