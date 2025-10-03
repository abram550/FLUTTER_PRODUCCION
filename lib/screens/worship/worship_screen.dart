import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/auth_service.dart';
import '../../models/song_list_model.dart';

// Define COCEP theme colors
class CocepColors {
  static const Color primary = Color(0xFF006D77); // Teal from logo
  static const Color secondary = Color(0xFFFF6B35); // Orange-red from flame
  static const Color accent = Color(0xFFFFB800); // Yellow from flame
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF2F3E46);
}

class WorshipScreen extends StatefulWidget {
  const WorshipScreen({super.key});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _serviceTypeController = TextEditingController(); // New controller
  final List<TextEditingController> _songControllers = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _serviceTypeController.dispose();
    for (var controller in _songControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    context.go('/');
  }

  void _addSongField() {
    setState(() {
      _songControllers.add(TextEditingController());
    });
  }

  Map<String, List<SongListModel>> agruparListas(List<SongListModel> listas) {
    Map<String, List<SongListModel>> grupos = {};

    for (var lista in listas) {
      DateTime fecha = lista.serviceDate;
      String anio = DateFormat.y('es').format(fecha);
      String mes = DateFormat.MMMM('es').format(fecha).toUpperCase();
      DateTime lunesDeEsaSemana =
          fecha.subtract(Duration(days: fecha.weekday - 1));
      String semana =
          "Semana del ${DateFormat('dd', 'es').format(lunesDeEsaSemana)} al ${DateFormat('dd', 'es').format(lunesDeEsaSemana.add(const Duration(days: 6)))}";
      String clave = "$anio - $mes - $semana";
      grupos.putIfAbsent(clave, () => []).add(lista);
    }
    return grupos;
  }

  Future<void> _showCreateSongListDialog() async {
    _songControllers.clear();
    _songControllers.add(TextEditingController());
    _dateController.clear();
    _serviceTypeController.clear();

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Crear Lista de Canciones',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CocepColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'Fecha del Servicio',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.calendar_today,
                                    color: CocepColors.primary),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: CocepColors.primary,
                                          onPrimary: Colors.white,
                                          surface: CocepColors.surface,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  _dateController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Seleccione la fecha'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _serviceTypeController,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Servicio',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.church,
                                    color: CocepColors.primary),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Ingrese el tipo de servicio'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            ..._songControllers.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: entry.value,
                                        decoration: InputDecoration(
                                          labelText: 'Canción ${entry.key + 1}',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          prefixIcon: const Icon(
                                              Icons.music_note,
                                              color: CocepColors.secondary),
                                        ),
                                        validator: (value) => value == null ||
                                                value.isEmpty
                                            ? 'Ingrese el nombre de la canción'
                                            : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: CocepColors.secondary),
                                      onPressed: () {
                                        setState(() {
                                          _songControllers.removeAt(entry.key);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _songControllers.add(TextEditingController());
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CocepColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Canción'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: CocepColors.text,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final songList = SongListModel(
                              id: '',
                              serviceDate: DateFormat('yyyy-MM-dd')
                                  .parse(_dateController.text),
                              songs: _songControllers
                                  .map((controller) => controller.text)
                                  .toList(),
                              createdAt: DateTime.now(),
                              serviceType: _serviceTypeController.text,
                            );

                            await FirebaseFirestore.instance
                                .collection('songLists')
                                .add(songList.toJson());

                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CocepColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditSongListDialog(SongListModel songList) async {
    _songControllers.clear();
    for (var song in songList.songs) {
      _songControllers.add(TextEditingController(text: song));
    }
    _dateController.text =
        DateFormat('yyyy-MM-dd').format(songList.serviceDate);
    _serviceTypeController.text =
        songList.serviceType; // Inicializar el tipo de servicio

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Lista de Canciones',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CocepColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'Fecha del Servicio',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.calendar_today,
                                    color: CocepColors.primary),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: songList.serviceDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: CocepColors.primary,
                                          onPrimary: Colors.white,
                                          surface: CocepColors.surface,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  _dateController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Seleccione la fecha'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            // Campo para editar el tipo de servicio
                            TextFormField(
                              controller: _serviceTypeController,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Servicio',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.church,
                                    color: CocepColors.primary),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Ingrese el tipo de servicio'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            ..._songControllers.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: entry.value,
                                        decoration: InputDecoration(
                                          labelText: 'Canción ${entry.key + 1}',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          prefixIcon: const Icon(
                                              Icons.music_note,
                                              color: CocepColors.secondary),
                                        ),
                                        validator: (value) => value == null ||
                                                value.isEmpty
                                            ? 'Ingrese el nombre de la canción'
                                            : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: CocepColors.secondary),
                                      onPressed: () {
                                        setState(() {
                                          _songControllers.removeAt(entry.key);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _songControllers.add(TextEditingController());
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CocepColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Canción'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: CocepColors.text,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await FirebaseFirestore.instance
                                .collection('songLists')
                                .doc(songList.id)
                                .update({
                              'serviceDate': DateFormat('yyyy-MM-dd')
                                  .parse(_dateController.text),
                              'songs':
                                  _songControllers.map((c) => c.text).toList(),
                              'serviceType': _serviceTypeController
                                  .text, // Guardar el tipo de servicio
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CocepColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteSongList(SongListModel songList) async {
    // Mostrar diálogo de confirmación
    bool confirmar = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar esta lista de canciones?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: CocepColors.text,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: CocepColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('songLists')
          .doc(songList.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CocepColors.background,
      appBar: AppBar(
        backgroundColor: CocepColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Alabanza',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('songLists')
            .orderBy('serviceDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar las listas de canciones',
                style: TextStyle(color: CocepColors.secondary),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(CocepColors.primary),
              ),
            );
          }

          final songLists = snapshot.data?.docs
                  .map((doc) => SongListModel.fromJson({
                        ...doc.data() as Map<String, dynamic>,
                        'id': doc.id,
                      }))
                  .toList() ??
              [];

          if (songLists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 64,
                    color: CocepColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay listas de canciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: CocepColors.text.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final listasAgrupadas = agruparListas(songLists);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: listasAgrupadas.entries.map((entrada) {
              final partes = entrada.key.split(' - ');
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CocepColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partes[0], // Año
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partes[1], // Mes
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partes[2], // Semana
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...entrada.value.map((songList) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Card(
                          elevation: 0,
                          color: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ExpansionTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lista para: ${DateFormat('EEEE', 'es').format(songList.serviceDate).capitalize()}',
                                  style: TextStyle(
                                    color: CocepColors.text,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (songList.serviceType.isNotEmpty)
                                  Text(
                                    'Tipo: ${songList.serviceType}',
                                    style: TextStyle(
                                      color: CocepColors.text.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: CocepColors.secondary,
                                  ),
                                  onPressed: () =>
                                      _showEditSongListDialog(songList),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: CocepColors.secondary,
                                  ),
                                  onPressed: () => _deleteSongList(songList),
                                ),
                                const Icon(Icons.expand_more),
                              ],
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: songList.songs.length,
                                itemBuilder: (context, songIndex) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: CocepColors.accent,
                                      child: Text(
                                        '${songIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      songList.songs[songIndex],
                                      style: TextStyle(color: CocepColors.text),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSongListDialog,
        backgroundColor: CocepColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Lista'),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
