import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    return getUserById(user.uid);
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      appLogger.e('Error fetching user: $e');
      return null;
    }
  }

  Future<UserModel> registerTeacher({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    // Validate college email
    final emailDomain = email.split('@').last.toLowerCase();
    if (AppConstants.blockedEmailDomains.contains(emailDomain)) {
      throw Exception('Please use your college/institutional email address.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: AppConstants.roleTeacher,
      department: department,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    appLogger.i('Teacher registered: ${user.uid}');
    return user;
  }

  Future<UserModel> registerStudent({
    required String name,
    required String email,
    required String password,
    required String enrollmentNumber,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: AppConstants.roleStudent,
      enrollmentNumber: enrollmentNumber,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    appLogger.i('Student registered: ${user.uid}');
    return user;
  }

  Future<UserModel> loginTeacher({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = await getUserById(cred.user!.uid);
    if (user == null || user.role != AppConstants.roleTeacher) {
      await _auth.signOut();
      throw Exception('No teacher account found for this email.');
    }
    return user;
  }

  Future<UserModel> loginStudent({
    required String enrollmentNumber,
    required String password,
  }) async {
    // Find student by enrollment number
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('enrollmentNumber', isEqualTo: enrollmentNumber)
        .where('role', isEqualTo: AppConstants.roleStudent)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No student found with this enrollment number.');
    }

    final studentData = UserModel.fromMap(query.docs.first.data());
    await _auth.signInWithEmailAndPassword(
      email: studentData.email,
      password: password,
    );

    return studentData;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    appLogger.i('User signed out');
  }
}