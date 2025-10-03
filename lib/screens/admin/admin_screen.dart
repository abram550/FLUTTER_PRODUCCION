import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/password_util.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _adminFormKey = GlobalKey<FormState>();
  final _userFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _hasProductionUser = false;
  bool _hasWorshipUser = false;

  bool _isLoadingAdmin = false;
  bool _isLoading = false;
  bool _isLoadingUser = false;
  String? _errorMessage;
  String _selectedRole = 'production';
  bool _showAdminCredentialsForm = false;
  bool _showCreateUserForm = false;
  bool _isAdminPasswordVisible = false;
  bool _isUserPasswordVisible = false;
  Map<String, dynamic>? _adminCredentials;

  bool _hasChangedAdminCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkAdminCredentialsStatus();
    _loadAdminCredentials();
  }

  Future<void> _loadAdminCredentials() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('adminCredentials')
          .doc('admin')
          .get();

      setState(() {
        _adminCredentials = doc.data();
        _showAdminCredentialsForm = !doc.exists;
      });
    } catch (e) {
      print('Error loading admin credentials: $e');
    }
  }

  Future<void> _checkAdminCredentialsStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('adminCredentials')
          .doc('admin')
          .get();
      setState(() {
        _hasChangedAdminCredentials = doc.exists;
      });
    } catch (e) {
      print('Error checking admin credentials: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingUsers() async {
    try {
      final productionUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'production')
          .get();

      final worshipUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worship')
          .get();

      setState(() {
        _showCreateUserForm =
            productionUsers.docs.isEmpty || worshipUsers.docs.isEmpty;
      });
    } catch (e) {
      print('Error checking existing users: $e');
    }
  }

  Future<void> _changeAdminCredentials() async {
    if (!_adminFormKey.currentState!.validate()) return;

    setState(() {
      _isLoadingAdmin = true;
      _errorMessage = null;
    });

    try {
      final hashedPassword =
          PasswordUtil.hashPassword(_passwordController.text);

      await FirebaseFirestore.instance
          .collection('adminCredentials')
          .doc('admin')
          .set({
        'username': _usernameController.text,
        'password':
            _passwordController.text, // Store plain password for display
        'hashedPassword': hashedPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadAdminCredentials();
      setState(() {
        _showAdminCredentialsForm = false;
        _hasChangedAdminCredentials = true;
      });

      if (!mounted) return;
      _showSnackBar('Credenciales actualizadas con éxito');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al actualizar credenciales: $e';
      });
      _showSnackBar(_errorMessage!);
    } finally {
      setState(() {
        _isLoadingAdmin = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00838F), // Teal color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _createUserCredentials() async {
    if (!_userFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hashedPassword =
          PasswordUtil.hashPassword(_newPasswordController.text);
      await FirebaseFirestore.instance.collection('users').add({
        'username': _newUsernameController.text,
        'password': _newPasswordController.text,
        'hashedPassword': hashedPassword,
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _showCreateUserForm = false;
      });

      _showSnackBar('Usuario creado con éxito');
      _newUsernameController.clear();
      _newPasswordController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al crear usuario: $e';
      });
      _showSnackBar(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    context.go('/');
  }

  Widget _buildAdminCredentialsForm() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Actualizar Credenciales Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00838F), // Teal color
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Nuevo Usuario Admin',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF00838F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF00838F), width: 2),
                ),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Por favor ingrese el nuevo usuario'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña Admin',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF00838F)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isAdminPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xFF00838F),
                  ),
                  onPressed: () => setState(() {
                    _isAdminPasswordVisible = !_isAdminPasswordVisible;
                  }),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF00838F), width: 2),
                ),
              ),
              obscureText: !_isAdminPasswordVisible,
              validator: (value) => value?.isEmpty ?? true
                  ? 'Por favor ingrese la nueva contraseña'
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoadingAdmin ? null : _changeAdminCredentials,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isLoadingAdmin
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Actualizar Credenciales',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateUserForm() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _userFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crear Nuevo Usuario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00838F),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _newUsernameController,
              decoration: InputDecoration(
                labelText: 'Usuario',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF00838F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF00838F), width: 2),
                ),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Por favor ingrese el usuario'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF00838F)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isUserPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xFF00838F),
                  ),
                  onPressed: () => setState(() {
                    _isUserPasswordVisible = !_isUserPasswordVisible;
                  }),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF00838F), width: 2),
                ),
              ),
              obscureText: !_isUserPasswordVisible,
              validator: (value) => value?.isEmpty ?? true
                  ? 'Por favor ingrese la contraseña'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Rol',
                prefixIcon: const Icon(Icons.work, color: Color(0xFF00838F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF00838F), width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'production',
                  child: Text('Producción'),
                ),
                DropdownMenuItem(
                  value: 'worship',
                  child: Text('Alabanza'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createUserCredentials,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Crear Usuario',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar usuarios',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00838F)),
            ),
          );
        }

        final users = snapshot.data?.docs
                .map((doc) => UserModel.fromJson({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }))
                .toList() ??
            [];

        _hasProductionUser = users.any((user) => user.role == 'production');
        _hasWorshipUser = users.any((user) => user.role == 'worship');

        if (_hasProductionUser && _hasWorshipUser && _showCreateUserForm) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _showCreateUserForm = false;
            });
          });
        }

        // Actualizar las opciones del dropdown basado en los usuarios existentes
        if (_hasProductionUser) {
          _selectedRole = 'worship';
        } else if (_hasWorshipUser) {
          _selectedRole = 'production';
        }

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No hay usuarios registrados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.teal.shade50,
                    ],
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Icon(
                        user.role == 'production'
                            ? Icons.video_camera_front
                            : Icons.music_note,
                        color: const Color(0xFF00838F),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Rol: ${user.role == 'production' ? 'Producción' : 'Alabanza'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contraseña: ${user.password}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.login, size: 18),
                              label: Text(
                                'Ir a ${user.role == 'production' ? 'Producción' : 'Alabanza'}',
                              ),
                              onPressed: () => context.go('/${user.role}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00838F),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF00838F)),
                            onPressed: () => _showEditUserDialog(user),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side:
                                    const BorderSide(color: Color(0xFF00838F)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditUserDialog(UserModel user) async {
    final editUsernameController = TextEditingController(text: user.username);
    final editPasswordController = TextEditingController(text: user.password);
    bool isPasswordVisible = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF00838F)),
              const SizedBox(width: 8),
              const Text('Editar Usuario'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editUsernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFF00838F)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editPasswordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF00838F)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF00838F),
                    ),
                    onPressed: () => setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    }),
                  ),
                ),
                obscureText: !isPasswordVisible,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final hashedPassword =
                    PasswordUtil.hashPassword(editPasswordController.text);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .update({
                  'username': editUsernameController.text,
                  'password': editPasswordController.text,
                  'hashedPassword': hashedPassword,
                });
                if (!mounted) return;
                Navigator.pop(context);
                _showSnackBar('Usuario actualizado con éxito');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel de Administración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          // Actualizar estados basados en los usuarios existentes
          if (snapshot.hasData) {
            final users = snapshot.data!.docs
                .map((doc) => UserModel.fromJson({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }))
                .toList();

            _hasProductionUser = users.any((user) => user.role == 'production');
            _hasWorshipUser = users.any((user) => user.role == 'worship');

            // Ocultar el formulario si ambos usuarios existen
            if (_hasProductionUser && _hasWorshipUser) {
              _showCreateUserForm = false;
            }

            // Actualizar el rol seleccionado basado en el usuario que falta
            if (_hasProductionUser && !_hasWorshipUser) {
              _selectedRole = 'worship';
            } else if (!_hasProductionUser && _hasWorshipUser) {
              _selectedRole = 'production';
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasChangedAdminCredentials && _adminCredentials != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.teal.shade50,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Credenciales de Administrador',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00838F),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF00838F),
                                  ),
                                  onPressed: () => setState(
                                      () => _showAdminCredentialsForm = true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Usuario: ${_adminCredentials!['username']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contraseña: ${_adminCredentials!['password']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_showAdminCredentialsForm) _buildAdminCredentialsForm(),
                if (!_showCreateUserForm &&
                    (!_hasProductionUser || !_hasWorshipUser))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Usuario'),
                      onPressed: () =>
                          setState(() => _showCreateUserForm = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00838F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (_showCreateUserForm &&
                    (!_hasProductionUser || !_hasWorshipUser))
                  _buildCreateUserForm(),
                const SizedBox(height: 24),
                const Text(
                  'Usuarios Existentes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
                const SizedBox(height: 16),
                _buildUsersList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
