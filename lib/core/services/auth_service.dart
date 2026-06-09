import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../bootstrap/backend_bootstrap.dart';
import '../data/demo_data.dart';
import '../models/app_models.dart';

class AuthResult {
  const AuthResult({required this.user, this.notice});

  final AppUser user;
  final String? notice;
}

class AuthService {
  AuthService(this.backendState);

  final BackendState backendState;

  bool get isFirebaseReady => backendState.firebaseReady;

  Future<AuthResult> signIn({
    required String email,
    required String password,
    required AppRole selectedRole,
  }) async {
    if (!isFirebaseReady) {
      return AuthResult(
        user: DemoData.userForRole(selectedRole),
        notice: 'Mock mode: Firebase is not configured yet.',
      );
    }

    final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final user = await _getOrCreateProfile(
      uid: uid,
      email: credential.user!.email ?? email.trim(),
      selectedRole: selectedRole,
      fallbackName: credential.user!.displayName ?? selectedRole.label,
    );

    final allowPending = dotenv.env['ALLOW_PENDING_DEMO_LOGIN']?.toLowerCase() == 'true';
    if (user.status != 'approved' && !allowPending && user.role != AppRole.citizen) {
      await fb.FirebaseAuth.instance.signOut();
      throw Exception('This ${user.role.label} account is still ${user.status}. Ask an admin to approve it.');
    }

    return AuthResult(user: user);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required AppRole selectedRole,
    required String fullName,
    String? phone,
    String? address,
  }) async {
    if (!isFirebaseReady) {
      return AuthResult(
        user: DemoData.userForRole(selectedRole),
        notice: 'Mock registration complete. Add Firebase credentials for real auth.',
      );
    }

    final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(fullName.trim());

    final uid = credential.user!.uid;
    final status = selectedRole == AppRole.citizen ? 'approved' : 'pending';
    final appUser = AppUser(
      id: uid,
      authId: uid,
      email: email.trim(),
      fullName: fullName.trim().isEmpty ? selectedRole.label : fullName.trim(),
      role: selectedRole,
      status: status,
      phone: phone,
      address: address,
    );

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...appUser.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return AuthResult(
      user: appUser,
      notice: status == 'pending' ? 'Account created. Admin approval is required for full access.' : null,
    );
  }

  Future<void> signOut() async {
    if (isFirebaseReady) {
      await fb.FirebaseAuth.instance.signOut();
    }
  }

  Future<AppUser?> currentUser() async {
    if (!isFirebaseReady) return null;
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return _readProfile(firebaseUser.uid);
  }

  Future<AppUser> _getOrCreateProfile({
    required String uid,
    required String email,
    required AppRole selectedRole,
    required String fallbackName,
  }) async {
    final profile = await _readProfile(uid);
    if (profile != null) return profile;

    final created = AppUser(
      id: uid,
      authId: uid,
      email: email,
      fullName: fallbackName,
      role: selectedRole,
      status: selectedRole == AppRole.citizen ? 'approved' : 'pending',
    );

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...created.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return created;
  }

  Future<AppUser?> _readProfile(String uid) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AppUser.fromMap(snapshot.id, data);
  }
}
