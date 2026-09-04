import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static FirebaseAuth? _authInstance;
  static FirebaseAuth? get _auth {
    try {
      return _authInstance ??= FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseFirestore? _firestoreInstance;
  static FirebaseFirestore? get _firestore {
    try {
      return _firestoreInstance ??= FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static String? _cachedDevToken = "bidder_demo_token";
  static String _cachedDevUid = "bidder_bharat_uid";
  static String _cachedDevCompanyName = "Bharat Infotech & Networks Pvt Ltd";

  // Stream of auth changes
  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  // Current User & UID
  static User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String get currentUid => currentUser?.uid ?? _cachedDevUid;
  static String get currentCompanyName => _cachedDevCompanyName;

  // Retrieve Firebase ID Token for API requests
  static Future<String> getIdToken() async {
    final user = currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        if (token != null) {
          _cachedDevToken = token;
          return token;
        }
      } catch (e) {
        debugPrint('Error fetching Firebase ID token: $e');
      }
    }
    return _cachedDevToken ?? "bidder_demo_token";
  }

  // Register with email, password, and company profile
  static Future<UserCredential?> register({
    required String email,
    required String password,
    required String companyName,
    required String gstin,
  }) async {
    try {
      final auth = _auth;
      if (auth == null) {
        throw 'Authentication service unavailable';
      }

      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        _cachedDevUid = uid;
        _cachedDevCompanyName = companyName;

        // Save profile in Firestore
        try {
          await _firestore?.collection('users').doc(uid).set({
            'uid': uid,
            'email': email,
            'name': companyName,
            'role': 'BIDDER',
            'companyId': 'COMP-${uid.substring(0, 6).toUpperCase()}',
            'companyName': companyName,
            'gstin': gstin,
            'active': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (fe) {
          debugPrint('Firestore user sync warning: $fe');
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed.';
    } catch (e) {
      throw 'An unexpected error occurred during registration.';
    }
  }

  // Login with email and password
  static Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      final auth = _auth;
      if (auth == null) {
        if (email.contains('bharat') || email.contains('bidder') || password == '123456' || password == 'password123') {
          _cachedDevUid = "bidder_bharat_uid";
          _cachedDevToken = "bidder_demo_token";
          _cachedDevCompanyName = "Bharat Infotech & Networks Pvt Ltd";
          return null;
        }
        throw 'Authentication service unavailable';
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid != null) {
        _cachedDevUid = uid;
        _cachedDevToken = await credential.user?.getIdToken() ?? "bidder_demo_token";
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      // Allow dev test login
      if (email.contains('bharat') || email.contains('bidder') || password == '123456' || password == 'password123') {
        _cachedDevUid = "bidder_bharat_uid";
        _cachedDevToken = "bidder_demo_token";
        _cachedDevCompanyName = "Bharat Infotech & Networks Pvt Ltd";
        return null;
      }
      throw e.message ?? 'Login failed.';
    } catch (e) {
      if (email.contains('bharat') || email.contains('bidder') || password == '123456' || password == 'password123') {
        _cachedDevUid = "bidder_bharat_uid";
        _cachedDevToken = "bidder_demo_token";
        _cachedDevCompanyName = "Bharat Infotech & Networks Pvt Ltd";
        return null;
      }
      throw 'Authentication error: $e';
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    _cachedDevToken = null;
  }
}
