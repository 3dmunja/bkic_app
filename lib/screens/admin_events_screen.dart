import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../services/api_helper.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  static const String listEndpoint = adminEventsEndpoint;
  static const String saveEndpoint = adminEventSaveEndpoint;
  static const String deleteEndpoint = adminEventDeleteEndpoint;
  static const String uploadEndpoint = adminEventUploadImageEndpoint;

  bool loading = true;
  bool saving = false;
  String error = '';
  String editingId = '';

  File? selectedImageFile;

  List<Map<String, dynamic>> events = [];

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final imageUrlController = TextEditingController();
  final detailsUrlController = TextEditingController();
  final maxSeatsController = TextEditingController();
  final deadlineController = TextEditingController();

  String category = 'predavanje';
  String status = 'open';

  @override
  void initState() {
    super.initState();
    fetchEvents();

    imageUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    detailsUrlController.dispose();
    maxSeatsController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final res = await ApiHelper.getJson(
        listEndpoint,
        includeAuthIfAvailable: true,
      );

      final raw = res['data'];

      final rawList = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        events = rawList;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Greška pri učitavanju događaja: $e';
        loading = false;
      });
    }
  }

  String _readString(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  int _readInt(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Vælg dato',
      cancelText: 'Annuller',
      confirmText: 'Angiv',
    );

    if (picked == null) return;

    controller.text =
        '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Vælg tid',
      cancelText: 'Annuller',
      confirmText: 'Angiv',
    );

    if (picked == null) return;

    timeController.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      selectedImageFile = File(picked.path);
    });

    _showMessage('Billede valgt.');
  }

  Future<String> _uploadSelectedImageIfNeeded() async {
    if (selectedImageFile == null) {
      return imageUrlController.text.trim();
    }

    final res = await ApiHelper.postMultipart(
      uploadEndpoint,
      authRequired: true,
      fields: const {},
      fileFieldName: 'image',
      file: selectedImageFile!,
    );

    final data = res['data'];
    String imageUrl = '';

    if (data is Map && data['url'] != null) {
      imageUrl = data['url'].toString().trim();
    } else if (res['url'] != null) {
      imageUrl = res['url'].toString().trim();
    }

    if (imageUrl.isEmpty) {
      throw Exception('Billedet blev uploadet, men serveren returnerede ingen URL.');
    }

    imageUrlController.text = imageUrl;
    return imageUrl;
  }

  void _resetForm() {
    setState(() {
      editingId = '';
      category = 'predavanje';
      status = 'open';
      selectedImageFile = null;
    });

    titleController.clear();
    descriptionController.clear();
    dateController.clear();
    timeController.clear();
    locationController.clear();
    priceController.clear();
    imageUrlController.clear();
    detailsUrlController.clear();
    maxSeatsController.clear();
    deadlineController.clear();
  }

  void _editEvent(Map<String, dynamic> item) {
    setState(() {
      editingId = _readString(item, 'id');
      selectedImageFile = null;
      category = _readString(item, 'category').isNotEmpty
          ? _readString(item, 'category')
          : 'predavanje';
      status = _readString(item, 'status').isNotEmpty
          ? _readString(item, 'status')
          : 'open';
    });

    titleController.text = _readString(item, 'title');
    descriptionController.text = _readString(item, 'description');
    dateController.text = _readString(item, 'date');
    timeController.text = _readString(item, 'time');
    locationController.text = _readString(item, 'location');
    priceController.text = _readString(item, 'price');
    imageUrlController.text = _readString(item, 'imageUrl');
    detailsUrlController.text = _readString(item, 'detailsUrl');
    maxSeatsController.text = _readString(item, 'maxSeats');
    deadlineController.text = _readString(item, 'deadline');
  }

  Future<void> _saveEvent() async {
    if (titleController.text.trim().isEmpty) {
      _showMessage('Naslov nedostaje.', isError: true);
      return;
    }

    if (dateController.text.trim().isEmpty) {
      _showMessage('Datum nedostaje.', isError: true);
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final imageUrl = await _uploadSelectedImageIfNeeded();

      final res = await ApiHelper.postJson(
        saveEndpoint,
        authRequired: true,
        body: {
          'id': editingId,
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'date': dateController.text.trim(),
          'time': timeController.text.trim(),
          'location': locationController.text.trim(),
          'price': priceController.text.trim(),
          'category': category,
          'status': status,
          'detailsUrl': detailsUrlController.text.trim(),
          'imageUrl': imageUrl,
          'maxSeats': maxSeatsController.text.trim(),
          'deadline': deadlineController.text.trim(),
        },
      );

      if (!mounted) return;

      _showMessage((res['message'] ?? 'Događaj je sačuvan.').toString());

      _resetForm();
      await fetchEvents();
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

  Future<void> _deleteEvent(Map<String, dynamic> item) async {
    final id = _readString(item, 'id');
    final title = _readString(item, 'title');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obrisati događaj?'),
        content: Text(
          title.isNotEmpty
              ? 'Da li želite obrisati "$title"?'
              : 'Da li želite obrisati ovaj događaj?',
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

      _showMessage((res['message'] ?? 'Događaj je obrisan.').toString());

      await fetchEvents();
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
    TextInputType keyboardType = TextInputType.text,
    String hint = '',
    VoidCallback? onTap,
    bool readOnly = false,
    IconData? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
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

  Widget _dropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF171715),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
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
      ),
    );
  }

  Widget _imagePickerBox() {
    final hasUrl = imageUrlController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Slika događaja',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (selectedImageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                selectedImageFile!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (hasUrl)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrlController.text.trim(),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Odaberi sliku'),
                ),
              ),
              if (selectedImageFile != null || hasUrl) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: saving
                      ? null
                      : () {
                          setState(() {
                            selectedImageFile = null;
                            imageUrlController.clear();
                          });
                        },
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _field(
            'Slika URL',
            imageUrlController,
            hint: 'Indsæt billede-link fra WordPress',
          ),
        ],
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
            editingId.isEmpty ? 'Dodaj novi događaj' : 'Uredi događaj',
            style: const TextStyle(
              color: Color(0xFFC9D4FF),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _field('Naslov', titleController),
          _field('Opis', descriptionController, maxLines: 5),
          _field(
            'Datum',
            dateController,
            hint: 'npr. 25.12.2026',
            readOnly: true,
            onTap: () => _pickDate(dateController),
            suffixIcon: Icons.calendar_month_outlined,
          ),
          _field(
            'Vrijeme',
            timeController,
            hint: 'npr. 18:00',
            readOnly: true,
            onTap: _pickTime,
            suffixIcon: Icons.access_time,
          ),
          _field('Mjesto', locationController),
          _field('Cijena', priceController, hint: 'Besplatno / 20 DKK'),
          _dropdown(
            label: 'Kategorija',
            value: category,
            items: const [
              DropdownMenuItem(value: 'predavanje', child: Text('Predavanje')),
              DropdownMenuItem(value: 'druzenje', child: Text('Druženje')),
              DropdownMenuItem(value: 'radionica', child: Text('Radionica')),
              DropdownMenuItem(value: 'omladina', child: Text('Omladina')),
              DropdownMenuItem(value: 'porodica', child: Text('Porodica')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => category = value);
            },
          ),
          _dropdown(
            label: 'Status',
            value: status,
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Otvoreno')),
              DropdownMenuItem(value: 'soon', child: Text('Uskoro')),
              DropdownMenuItem(value: 'closed', child: Text('Zatvoreno')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => status = value);
            },
          ),
          _field(
            'Maksimalan broj mjesta',
            maxSeatsController,
            keyboardType: TextInputType.number,
            hint: '0 = bez ograničenja',
          ),
          _field(
            'Rok prijave',
            deadlineController,
            hint: 'npr. 24.12.2026',
            readOnly: true,
            onTap: () => _pickDate(deadlineController),
            suffixIcon: Icons.calendar_month_outlined,
          ),
          _field('Link za detalje', detailsUrlController),
          _imagePickerBox(),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : _saveEvent,
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

  Widget _eventCard(Map<String, dynamic> item) {
    final title = _readString(item, 'title');
    final date = _readString(item, 'date');
    final time = _readString(item, 'time');
    final categoryLabel = _readString(item, 'categoryLabel');
    final statusLabel = _readString(item, 'statusLabel');
    final availabilityLabel = _readString(item, 'availabilityLabel');
    final imageUrl = _readString(item, 'imageUrl');
    final count = _readInt(item, 'registrationsCount');
    final maxSeats = _readInt(item, 'maxSeats');

    final rawRegistrations = item['registrations'];

    final registrations = rawRegistrations is List
        ? rawRegistrations
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

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
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 170,
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          if (imageUrl.isNotEmpty) const SizedBox(height: 14),
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
            '$categoryLabel • $statusLabel • $date $time',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            maxSeats > 0
                ? 'Broj prijavljenih: $count / $maxSeats'
                : 'Broj prijavljenih: $count',
            style: const TextStyle(
              color: Color(0xFFD3B261),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (availabilityLabel.isNotEmpty)
            Text(
              'Status prijave: $availabilityLabel',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 12),
          if (registrations.isEmpty)
            const Text(
              'Niko se još nije prijavio.',
              style: TextStyle(color: Colors.white54),
            )
          else
            ExpansionTile(
              collapsedIconColor: Colors.white70,
              iconColor: Colors.white,
              title: const Text(
                'Lista prijavljenih',
                style: TextStyle(color: Colors.white),
              ),
              children: registrations.map((reg) {
                return ListTile(
                  dense: true,
                  title: Text(
                    _readString(reg, 'display_name').isNotEmpty
                        ? _readString(reg, 'display_name')
                        : 'Korisnik',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${_readString(reg, 'user_email')}\n${_readString(reg, 'registered_at')}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editEvent(item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Uredi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteEvent(item),
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
            onPressed: fetchEvents,
            child: const Text('Pokušaj ponovo'),
          ),
        ],
      );
    }

    if (events.isEmpty) {
      return const Text(
        'Nema događaja.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: events.map(_eventCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchEvents,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Događaji – Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kreiraj, uređuj, briši i prati prijave.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          _formCard(),
          const SizedBox(height: 22),
          const Text(
            'Postojeći događaji',
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