import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        await _auth.signOut();
        _setError('Please check your inbox and verify your email first.');
        _setLoading(false);
        return false;
      }

      await _saveLocalUser(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during sign in');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _auth.currentUser?.sendEmailVerification();
      await _auth.signOut(); // User must log in after verification
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during sign up');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false; // User canceled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user?.email != null) {
        await _saveLocalUser(userCredential.user!.email!);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during Google Sign-In');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Failed to send reset email');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserEmail);
    notifyListeners();
  }

  Future<void> _saveLocalUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserName, email.split('@').first);
    await prefs.setString(AppConstants.keyUserEmail, email);
  }
}
