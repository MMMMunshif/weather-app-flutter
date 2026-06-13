import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// EVENTS

abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({
    required this.email,
    required this.password,
  });
}

class SignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  SignupRequested({
    required this.name,
    required this.email,
    required this.password,
  });
}

class LogoutRequested extends AuthEvent {}

// STATES

abstract class AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String uid;
  final String email;
  final String name;

  AuthAuthenticated({
    required this.uid,
    required this.email,
    required this.name,
  });
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure({
    required this.message,
  });
}

class AuthSignupSuccess extends AuthState {
  final String message;

  AuthSignupSuccess({
    required this.message,
  });
}

// BLOC

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthLoading()) {
    on<AuthCheckRequested>(_checkLoginStatus);
    on<LoginRequested>(_login);
    on<SignupRequested>(_signup);
    on<LogoutRequested>(_logout);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _checkLoginStatus(
      AuthCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final User? user = await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );

      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }

      Map<String, dynamic> userData = {};

      try {
        userData = await _getUserData(user.uid).timeout(
          const Duration(seconds: 4),
          onTimeout: () => <String, dynamic>{},
        );
      } catch (_) {
        userData = {};
      }

      emit(
        AuthAuthenticated(
          uid: user.uid,
          email: user.email ?? '',
          name: userData['name'] ?? user.displayName ?? 'User',
        ),
      );
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _login(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    final String email = event.email.trim();
    final String password = event.password.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(AuthFailure(message: 'Please enter email and password.'));
      return;
    }

    if (!email.contains('@')) {
      emit(AuthFailure(message: 'Please enter a valid email address.'));
      return;
    }

    if (password.length < 6) {
      emit(AuthFailure(message: 'Password must be at least 6 characters.'));
      return;
    }

    emit(AuthLoading());

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        emit(AuthFailure(message: 'Login failed. Please try again.'));
        return;
      }

      Map<String, dynamic> userData = {};

      try {
        userData = await _getUserData(user.uid).timeout(
          const Duration(seconds: 4),
          onTimeout: () => <String, dynamic>{},
        );
      } catch (_) {
        userData = {};
      }

      if (userData.isEmpty) {
        await _createUserDocumentIfMissing(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? email,
        );

        userData = {
          'name': user.displayName ?? 'User',
          'email': user.email ?? email,
        };
      }

      emit(
        AuthAuthenticated(
          uid: user.uid,
          email: user.email ?? email,
          name: userData['name'] ?? user.displayName ?? 'User',
        ),
      );
    } on FirebaseAuthException catch (error) {
      emit(
        AuthFailure(
          message: _firebaseAuthErrorMessage(error),
        ),
      );
    } catch (_) {
      emit(
        AuthFailure(
          message: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> _signup(
      SignupRequested event,
      Emitter<AuthState> emit,
      ) async {
    final String name = event.name.trim();
    final String email = event.email.trim();
    final String password = event.password.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      emit(AuthFailure(message: 'Please fill all fields.'));
      return;
    }

    if (!email.contains('@')) {
      emit(AuthFailure(message: 'Please enter a valid email address.'));
      return;
    }

    if (password.length < 6) {
      emit(AuthFailure(message: 'Password must be at least 6 characters.'));
      return;
    }

    emit(AuthLoading());

    try {
      final UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        emit(AuthFailure(message: 'Signup failed. Please try again.'));
        return;
      }

      await user.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': {
          'temperatureUnit': 'C',
          'windSpeedUnit': 'kmh',
          'darkMode': true,
          'severeWeatherAlerts': true,
          'dailyForecast': true,
          'precipitationAlerts': true,
          'themeIndex': 0,
        },
        'savedLocations': [],
        'trips': [],
      });

      // Important:
      // Signup success aana direct home page pogama,
      // user-a sign out panni login page-ku anuppurom.
      await _auth.signOut();

      emit(
        AuthSignupSuccess(
          message: 'Account created successfully. Please login now.',
        ),
      );
    } on FirebaseAuthException catch (error) {
      emit(
        AuthFailure(
          message: _firebaseAuthErrorMessage(error),
        ),
      );
    } catch (_) {
      emit(
        AuthFailure(
          message: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> _logout(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      await _auth.signOut();
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(
        AuthFailure(
          message: 'Logout failed. Please try again.',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
    await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return {};
    }

    return doc.data()!;
  }

  Future<void> _createUserDocumentIfMissing({
    required String uid,
    required String name,
    required String email,
  }) async {
    final DocumentReference<Map<String, dynamic>> userDoc =
    _firestore.collection('users').doc(uid);

    final DocumentSnapshot<Map<String, dynamic>> doc = await userDoc.get();

    if (doc.exists) return;

    await userDoc.set({
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'settings': {
        'temperatureUnit': 'C',
        'windSpeedUnit': 'kmh',
        'darkMode': true,
        'severeWeatherAlerts': true,
        'dailyForecast': true,
        'precipitationAlerts': true,
        'themeIndex': 0,
      },
      'savedLocations': [],
      'trips': [],
    });
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}