// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/password_util.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();
  String? _currentRole;
  bool _isAuthenticated = false;

  static const String defaultAdminUser = 'adminproalb'; //admin, producción, alabanza
  static const String defaultAdminPassword = 'AlbProd@25';

  bool get isAuthenticated => _isAuthenticated;
  String? get currentRole => _currentRole;

  Future<void> initializeApp() async {
    try {
      // Verificar si existe el documento de admin
      final adminDoc =
          await _firestore.collection('adminCredentials').doc('admin').get();
      if (!adminDoc.exists) {
        // Crear credenciales por defecto
        await _firestore.collection('adminCredentials').doc('admin').set({
          'username': defaultAdminUser,
          'password': defaultAdminPassword,
          'hashedPassword': PasswordUtil.hashPassword(defaultAdminPassword),
          'isDefaultCredentials': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing app: $e');
    }
  }

  Future<String?> getUserRole() async {
    return _currentRole;
  }

  Future<bool> login(String username, String password) async {
    try {
      // Verificar credenciales de admin
      final adminDoc =
          await _firestore.collection('adminCredentials').doc('admin').get();
      if (adminDoc.exists) {
        final adminData = adminDoc.data();
        if (adminData?['username'] == username &&
            PasswordUtil.verifyPassword(
                password, adminData?['hashedPassword'])) {
          _currentRole = 'admin';
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }

      // Verificar credenciales de usuarios de producción y alabanza
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        if (PasswordUtil.verifyPassword(password, userData['hashedPassword'])) {
          _currentRole = userData['role'];
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentRole = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getAdminCredentials() async {
    try {
      final doc =
          await _firestore.collection('adminCredentials').doc('admin').get();
      return doc.data();
    } catch (e) {
      print('Error al obtener credenciales de admin: $e');
      return null;
    }
  }

  Future<bool> changeAdminCredentials(
      String newUser, String newPassword) async {
    try {
      await _firestore.collection('adminCredentials').doc('admin').set({
        'username': newUser,
        'password': newPassword,
        'hashedPassword': PasswordUtil.hashPassword(newPassword),
        'isDefaultCredentials': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al cambiar credenciales de admin: $e');
      return false;
    }
  }

  Future<bool> createUser(String username, String password, String role) async {
    try {
      // Verificar si ya existe un usuario con ese rol
      final existingUsers = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        return false;
      }

      await _firestore.collection('users').add({
        'username': username,
        'password': password,
        'hashedPassword': PasswordUtil.hashPassword(password),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al crear usuario: $e');
      return false;
    }
  }
}
