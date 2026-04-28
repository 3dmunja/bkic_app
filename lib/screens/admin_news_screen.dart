import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  static const String listEndpoint = adminNewsEndpoint;
  static const String saveEndpoint = adminNewsSaveEndpoint;
  static const String deleteEndpoint = adminNewsDeleteEndpoint;

  bool loading = true;
  bool saving = false;
  String error = '';
  String editingId = '';

  List<Map<String, dynamic>> news = [];

  final titleController = TextEditingController();
  final textController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();

  String status = 'publish';

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  @override
  void dispose() {
    titleController.dispose();
    textController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  Future<void> fetchNews() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final res = await ApiHelper.getJson(
        listEndpoint,
        authRequired: true,
      );

      final raw = res['data'];

      final parsed = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        news = parsed;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri učitavanju vijesti: $e';
        loading = false;
      });
    }
  }

  String _readString(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Vælg dato',
      cancelText: 'Annuller',
      confirmText: 'Angiv',
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Vælg tid',
      cancelText: 'Annuller',
      confirmText: 'Angiv',
    );

    if (pickedTime == null) return;

    controller.text =
        '${pickedDate.day.toString().padLeft(2, '0')}.'
        '${pickedDate.month.toString().padLeft(2, '0')}.'
        '${pickedDate.year}, '
        '${pickedTime.hour.toString().padLeft(2, '0')}.'
        '${pickedTime.minute.toString().padLeft(2, '0')}';
  }

  void _resetForm() {
    setState(() {
      editingId = '';
      status = 'publish';
    });

    titleController.clear();
    textController.clear();
    startController.clear();
    endController.clear();
  }

  void _editNews(Map<String, dynamic> item) {
    setState(() {
      editingId = _readString(item, 'id');
      status = _readString(item, 'status') == 'draft' ? 'draft' : 'publish';
    });

    titleController.text = _readString(item, 'title');
    textController.text = _readString(item, 'text');
    startController.text = _readString(item, 'start');
    endController.text = _readString(item, 'end');
  }

  Future<void> _saveNews() async {
    if (titleController.text.trim().isEmpty) {
      _showMessage('Naslov nedostaje.', isError: true);
      return;
    }

    if (endController.text.trim().isEmpty) {
      _showMessage('Kraj / ističe nedostaje.', isError: true);
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final res = await ApiHelper.postJson(
        saveEndpoint,
        authRequired: true,
        body: {
          'id': editingId,
          'title': titleController.text.trim(),
          'text': textController.text.trim(),
          'start': startController.text.trim(),
          'end': endController.text.trim(),
          'status': status,
        },
      );

      if (!mounted) return;

      _showMessage((res['message'] ?? 'Vijest je sačuvana.').toString());

      _resetForm();
      await fetchNews();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Greška: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        saving = false;
      });
    }
  }

  Future<void> _deleteNews(Map<String, dynamic> item) async {
    final id = _readString(item, 'id');
    final title = _readString(item, 'title');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obrisati vijest?'),
        content: Text(
          title.isNotEmpty
              ? 'Da li želite obrisati "$title"?'
              : 'Da li želite obrisati ovu vijest?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiHelper.postJson(
        deleteEndpoint,
        authRequired: true,
        body: {'id': id},
      );

      if (!mounted) return;

      _showMessage((res['message'] ?? 'Vijest je obrisana.').toString());

      await fetchNews();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Greška pri brisanju: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String hint = '',
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon:
              suffixIcon == null ? null : Icon(suffixIcon, color: Colors.white70),
          filled: true,
          fillColor: const Color(0x14FFFFFF),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x22FFFFFF)),
          ),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: status,
        dropdownColor: const Color(0xFF171715),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Status',
          filled: true,
          fillColor: const Color(0x14FFFFFF),
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x22FFFFFF)),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'publish', child: Text('Publiceret')),
          DropdownMenuItem(value: 'draft', child: Text('Kladde')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => status = value);
        },
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171715),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editingId.isEmpty ? 'Dodaj novu vijest' : 'Uredi vijest',
            style: const TextStyle(
              color: Color(0xFFC9D4FF),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _field('Naslov', titleController),
          _field('Tekst', textController, maxLines: 6),
          _field(
            'Start',
            startController,
            hint: '13.02.2026, 11.48',
            readOnly: true,
            onTap: () => _pickDateTime(startController),
            suffixIcon: Icons.calendar_month_outlined,
          ),
          _field(
            'Kraj / Ističe',
            endController,
            hint: '14.02.2026, 11.48',
            readOnly: true,
            onTap: () => _pickDateTime(endController),
            suffixIcon: Icons.calendar_month_outlined,
          ),
          _dropdown(),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : _saveNews,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD3B261),
                    foregroundColor: const Color(0xFF111111),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          editingId.isEmpty ? 'Sačuvaj' : 'Ažuriraj',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
              if (editingId.isNotEmpty) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: saving ? null : _resetForm,
                  child: const Text('Otkaži'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _newsCard(Map<String, dynamic> item) {
    final title = _readString(item, 'title');
    final text = _readString(item, 'text');
    final start = _readString(item, 'start');
    final end = _readString(item, 'end');
    final itemStatus = _readString(item, 'status');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171715),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Bez naslova',
            style: const TextStyle(
              color: Color(0xFFF3D37D),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: $itemStatus',
            style: const TextStyle(color: Color(0xFFD3B261)),
          ),
          if (start.isNotEmpty)
            Text('Start: $start', style: const TextStyle(color: Colors.white70)),
          Text('Kraj: $end', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editNews(item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Uredi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteNews(item),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Obriši'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listCard() {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: fetchNews,
            child: const Text('Pokušaj ponovo'),
          ),
        ],
      );
    }

    if (news.isEmpty) {
      return const Text(
        'Nema vijesti.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: news.map(_newsCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchNews,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Vijesti – Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kreiraj, uređuj og slet vijesti.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          _formCard(),
          const SizedBox(height: 22),
          const Text(
            'Postojeće vijesti',
            style: TextStyle(
              color: Color(0xFFC9D4FF),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _listCard(),
        ],
      ),
    );
  }
}