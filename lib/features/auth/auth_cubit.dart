import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/utils.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    restoreSession();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  @override
  Future<void> close() {
    _userDocSubscription?.cancel();
    return super.close();
  }

  void _listenToUserDoc(String userId) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) async {
          try {
            if (doc.exists) {
              final data = doc.data();
              final roleString = data?['role'] as String?;
              var role = _mapRole(roleString);

              final isActive = data?['isActive'] as bool? ?? true;
              if (!isActive) {
                await logout();
                emit(AuthError(message: 'Your account has been suspended.'));
                return;
              }

              await AppSession.persistLogin(
                role: role,
                phone: _auth.currentUser?.email ?? '',
                userId: userId,
                name: data?['name'] as String?,
              );

              emit(
                AuthAuthenticated(
                  userId: userId,
                  role: role,
                  name: data?['name'] as String?,
                  email: data?['email'] as String?,
                  phone: data?['phone'] as String?,
                  photoUrl: data?['photoUrl'] as String?,
                  dob: data?['dob'] as String?,
                  gender: data?['gender'] as String?,
                  height: data?['height'] as String?,
                  weight: data?['weight'] as String?,
                  bloodGroup: data?['bloodGroup'] as String?,
                ),
              );
            } else {
              await _firestore.collection('users').doc(userId).set({
                'id': userId,
                'name': _auth.currentUser?.displayName ?? 'User',
                'email': _auth.currentUser?.email ?? '',
                'phone': _auth.currentUser?.phoneNumber ?? '',
                'role': 'user',
                'walletBalance': 0.0,
                'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (e) {
            emit(AuthError(message: 'Error synchronizing user data: $e'));
          }
        }, onError: (error) {
          emit(AuthError(message: 'Stream error: $error'));
        });
  }

  UserRole _mapRole(String? roleString) {
    return UserRole.fromString(roleString);
  }

  Future<void> restoreSession() async {
    try {
      var user = _auth.currentUser;
      if (user == null && AppSession.isLoggedIn) {
        user = await _auth.authStateChanges().first;
      }

      if (user != null) {
        if (user.isAnonymous) {
          emit(AuthUnauthenticated());
        } else {
          _listenToUserDoc(user.uid);
        }
        return;
      } else {
        await AppSession.clear();
      }
    } catch (e) {
      await AppSession.clear();
    }
    emit(AuthUnauthenticated());
  }

  Future<void> signIn(String identifier, String password) async {
    emit(AuthLoading());
    try {
      String authEmail = identifier.trim();
      if (!authEmail.contains('@')) {
        final cleanPhone = authEmail.replaceAll(RegExp(r'[^0-9+]'), '');
        try {
          final doc = await _firestore.collection('phone_directory').doc(cleanPhone).get();
          if (doc.exists && doc.data()?['email'] != null) {
            authEmail = doc.data()!['email'] as String;
          } else {
            String normalized = cleanPhone;
            if (normalized.startsWith('+88')) normalized = normalized.substring(3);
            if (normalized.startsWith('88') && normalized.length > 11) normalized = normalized.substring(2);
            final doc2 = await _firestore.collection('phone_directory').doc(normalized).get();
            if (doc2.exists && doc2.data()?['email'] != null) {
              authEmail = doc2.data()!['email'] as String;
            } else {
              authEmail = '$normalized@phone.healmeal.app';
            }
          }
        } catch (_) {
          authEmail = '$cleanPhone@phone.healmeal.app';
        }
      }

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: authEmail, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        _listenToUserDoc(user.uid);
      } else {
        emit(AuthError(message: 'Sign in failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signUp(
    String emailOrPhone,
    String password,
    String name,
    UserRole role, {
    String? phone,
  }) async {
    emit(AuthLoading());
    try {
      final resolvedRole = role;
      String authEmail = emailOrPhone.trim();
      String userEmail = authEmail;
      String userPhone = phone?.trim() ?? '';

      if (!authEmail.contains('@')) {
        final cleanPhone = authEmail.replaceAll(RegExp(r'[^0-9+]'), '');
        String normalized = cleanPhone;
        if (normalized.startsWith('+88')) normalized = normalized.substring(3);
        if (normalized.startsWith('88') && normalized.length > 11) normalized = normalized.substring(2);
        authEmail = '$normalized@phone.healmeal.app';
        userEmail = '';
        if (userPhone.isEmpty) userPhone = cleanPhone;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        final userData = {
          'id': user.uid,
          'name': name.trim(),
          'email': userEmail,
          'phone': userPhone,
          'role': resolvedRole.name,
          'walletBalance': 0.0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(user.uid).set(userData);

        if (userPhone.isNotEmpty) {
          try {
            final cleanPhone = userPhone.replaceAll(RegExp(r'[^0-9+]'), '');
            await _firestore.collection('phone_directory').doc(cleanPhone).set({
              'email': authEmail,
              'userId': user.uid,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }

        await AppSession.persistLogin(
          role: resolvedRole,
          phone: userPhone.isNotEmpty ? userPhone : userEmail,
          userId: user.uid,
          name: name,
        );
        _listenToUserDoc(user.uid);
      } else {
        emit(AuthError(message: 'Registration failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: e.message ?? 'Registration failed'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    _userDocSubscription?.cancel();
    await _auth.signOut();
    await AppSession.clear();
    try {
      await _auth.signInAnonymously();
    } catch (_) {}
    emit(AuthUnauthenticated());
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      emit(AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: e.message ?? 'Failed to send reset email'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.userId,
    required this.role,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.dob,
    this.gender,
    this.height,
    this.weight,
    this.bloodGroup,
  });

  final String userId;
  final UserRole role;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? dob;
  final String? gender;
  final String? height;
  final String? weight;
  final String? bloodGroup;

  @override
  List<Object?> get props => [
    userId,
    role,
    name,
    email,
    phone,
    photoUrl,
    dob,
    gender,
    height,
    weight,
    bloodGroup,
  ];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}
