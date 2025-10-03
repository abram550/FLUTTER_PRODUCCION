import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/word_model.dart';
import '../../models/song_list_model.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Define theme colors based on the COCEP logo
class AppColors {
  static const Color primary = Color(0xFF0D7B93); // Teal from globe
  static const Color secondary = Color(0xFFFFB347); // Orange from flame
  static const Color accent = Color(0xFFFF4040); // Red from flame bottom
  static const Color background = Color(0xFFF5F7F9); // Light background
  static const Color silver = Color(0xFF808080); // Silver from text

  // Gradient colors for cards
  static final List<Color> cardGradient = [
    const Color(0xFF0D7B93).withOpacity(0.05),
    const Color(0xFFFFB347).withOpacity(0.05),
  ];
}

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _wordTypeController = TextEditingController();
  final _serviceController = TextEditingController();
  final _streamLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting('es', null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _wordTypeController.dispose();
    _serviceController.dispose();
    _streamLinkController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _showAddWordDialog() async {
    return showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
              ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Agregar Palabra Recibida',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    controller: _nameController,
                    label: 'Nombre Completo',
                    icon: Icons.person,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  _buildDateField(),
                  _buildTimeField(
                    controller: _startTimeController,
                    label: 'Hora Inicio',
                    icon: Icons.access_time,
                  ),
                  _buildTimeField(
                    controller: _endTimeController,
                    label: 'Hora Fin',
                    icon: Icons.access_time_filled,
                  ),
                  _buildFormField(
                    controller: _wordTypeController,
                    label: 'Tipo de Palabra',
                    icon: Icons.category,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  _buildFormField(
                    controller: _serviceController,
                    label: 'Servicio',
                    icon: Icons.church,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  _buildFormField(
                    controller: _streamLinkController,
                    label: 'Link del Directo (Opcional)',
                    icon: Icons.link,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.silver),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _saveWord,
              child: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _dateController,
        decoration: InputDecoration(
          labelText: 'Fecha',
          prefixIcon:
              const Icon(Icons.calendar_today, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.primary,
                      ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            _dateController.text = DateFormat('yyyy-MM-dd').format(date);
          }
        },
        validator: (value) =>
            value?.isEmpty ?? true ? 'Por favor seleccione la fecha' : null,
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        readOnly: true,
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.primary,
                      ),
                ),
                child: child!,
              );
            },
          );
          if (time != null) {
            controller.text = time.format(context);
          }
        },
        validator: (value) =>
            value?.isEmpty ?? true ? 'Por favor seleccione la hora' : null,
      ),
    );
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      final word = WordModel(
        id: '',
        fullName: _nameController.text,
        date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        wordType: _wordTypeController.text,
        service: _serviceController.text,
        streamLink: _streamLinkController.text.isEmpty
            ? null
            : _streamLinkController.text,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('words').add(word.toJson());

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Palabra guardada exitosamente'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Clear controllers
      _nameController.clear();
      _dateController.clear();
      _startTimeController.clear();
      _endTimeController.clear();
      _wordTypeController.clear();
      _serviceController.clear();
      _streamLinkController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Cocep_.png', // Make sure to add your logo asset
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'Producción',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.9),
                ],
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.secondary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.speaker_notes),
                  text: 'Palabras Recibidas',
                ),
                Tab(
                  icon: Icon(Icons.music_note),
                  text: 'Canciones Asignadas',
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWordsTab(),
          _buildSongsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddWordDialog,
              backgroundColor: AppColors.secondary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva Palabra',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildWordsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.primary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('words')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar las palabras',
                    style: TextStyle(color: AppColors.accent),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              final words = snapshot.data?.docs
                      .map((doc) => WordModel.fromJson({
                            ...doc.data() as Map<String, dynamic>,
                            'id': doc.id,
                          }))
                      .where((word) {
                    final search = _searchController.text.toLowerCase();
                    return search.isEmpty ||
                        word.fullName.toLowerCase().contains(search);
                  }).toList() ??
                  [];

              // Si hay texto en el buscador, mostrar lista simple sin agrupación
              if (_searchController.text.isNotEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    return _buildWordCard(words[index]);
                  },
                );
              }

              // Si no hay búsqueda, mostrar lista agrupada
              final groupedWords = _groupWordsByDate(words);

              return ListView.builder(
                itemCount: groupedWords.length,
                itemBuilder: (context, yearIndex) {
                  final year = groupedWords.keys.elementAt(yearIndex);
                  final monthsMap = groupedWords[year]!;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          year,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        children: monthsMap.entries.map((monthEntry) {
                          return _buildMonthSection(
                              monthEntry.key, monthEntry.value);
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSection(
      String month, Map<String, List<WordModel>> weeksMap) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            month.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary.withOpacity(0.8),
            ),
          ),
          children: weeksMap.entries.map((weekEntry) {
            return _buildWeekSection(weekEntry.key, weekEntry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeekSection(String week, List<WordModel> words) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            week,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.silver,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: words.map((word) => _buildWordCard(word)).toList(),
        ),
      ),
    );
  }

  Widget _buildWordCard(WordModel word) {
    bool isToday = DateFormat('yyyy-MM-dd').format(word.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: isToday
                ? [
                    AppColors.secondary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ]
                : AppColors.cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            word.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(word.date),
                    style: const TextStyle(color: AppColors.silver),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${word.startTime} - ${word.endTime}',
                    style: const TextStyle(color: AppColors.silver),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildChip(
                    word.wordType,
                    AppColors.primary,
                    Icons.category,
                  ),
                  _buildChip(
                    word.service,
                    AppColors.secondary,
                    Icons.church,
                  ),
                ],
              ),
              if (word.streamLink != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: word.streamLink!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.check, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Link copiado al portapapeles'),
                              ],
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Copiar Link'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, Map<String, List<WordModel>>>> _groupWordsByDate(
      List<WordModel> words) {
    Map<String, Map<String, Map<String, List<WordModel>>>> grouped = {};

    for (var word in words) {
      String year = DateFormat.y('es').format(word.date);
      String month = DateFormat.MMMM('es').format(word.date);
      DateTime weekStart =
          word.date.subtract(Duration(days: word.date.weekday - 1));
      String week =
          "Semana del ${DateFormat('dd', 'es').format(weekStart)} al ${DateFormat('dd', 'es').format(weekStart.add(const Duration(days: 6)))}";

      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => {});
      grouped[year]![month]!.putIfAbsent(week, () => []);
      grouped[year]![month]![week]!.add(word);
    }

    return grouped;
  }

  Widget _buildSongsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('songLists')
          .orderBy('serviceDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar las listas de canciones',
              style: TextStyle(color: AppColors.accent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                  color: AppColors.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay listas de canciones asignadas',
                  style: TextStyle(
                    color: AppColors.silver,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final groupedLists = _groupSongsByDate(songLists);
        return _buildGroupedSongLists(groupedLists);
      },
    );
  }

  Map<String, Map<String, Map<String, List<SongListModel>>>> _groupSongsByDate(
      List<SongListModel> songLists) {
    Map<String, Map<String, Map<String, List<SongListModel>>>> grouped = {};

    for (var songList in songLists) {
      String year = DateFormat.y('es').format(songList.serviceDate);
      String month = DateFormat.MMMM('es').format(songList.serviceDate);
      DateTime weekStart = songList.serviceDate
          .subtract(Duration(days: songList.serviceDate.weekday - 1));
      String week =
          "Semana del ${DateFormat('dd', 'es').format(weekStart)} al ${DateFormat('dd', 'es').format(weekStart.add(const Duration(days: 6)))}";

      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => {});
      grouped[year]![month]!.putIfAbsent(week, () => []);
      grouped[year]![month]![week]!.add(songList);
    }

    return grouped;
  }

  Widget _buildGroupedSongLists(
      Map<String, Map<String, Map<String, List<SongListModel>>>> groupedLists) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: groupedLists.length,
      itemBuilder: (context, yearIndex) {
        final year = groupedLists.keys.elementAt(yearIndex);
        final monthsMap = groupedLists[year]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                year,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              children: monthsMap.entries.map((monthEntry) {
                return _buildSongMonthSection(monthEntry.key, monthEntry.value);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongMonthSection(
      String month, Map<String, List<SongListModel>> weeksMap) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            month.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary.withOpacity(0.8),
            ),
          ),
          children: weeksMap.entries.map((weekEntry) {
            return _buildSongWeekSection(weekEntry.key, weekEntry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSongWeekSection(String week, List<SongListModel> songLists) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              week,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.silver,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...songLists.map((songList) => _buildSongListCard(songList)),
        ],
      ),
    );
  }

  Widget _buildSongListCard(SongListModel songList) {
    bool isToday = DateFormat('yyyy-MM-dd').format(songList.serviceDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: isToday
                ? [
                    AppColors.secondary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ]
                : AppColors.cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ExpansionTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: isToday ? AppColors.secondary : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isToday
                          ? 'Lista para Hoy: ${DateFormat('EEEE', 'es').format(songList.serviceDate)}'
                          : 'Lista para: ${DateFormat('EEEE', 'es').format(songList.serviceDate)}',
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color:
                            isToday ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (songList.serviceType.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tipo de servicio: ${songList.serviceType}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.silver,
                    ),
                  ),
                ),
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
                    backgroundColor:
                        isToday ? AppColors.secondary : AppColors.primary,
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
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
