import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SectionsPage extends StatefulWidget {
  const SectionsPage({super.key});

  @override
  State<SectionsPage> createState() => _SectionsPageState();
}

class _SectionsPageState extends State<SectionsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    try {
      final data = await _supabase
          .from('sections')
          .select()
          .order('section_code', ascending: true);
      setState(() {
        _sections = List<Map<String, dynamic>>.from(data);
        _filteredSections = _sections;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar("Error fetching sections: $e", Colors.red);
    }
  }

  void _filterSections(String query) {
    setState(() {
      _filteredSections = _sections
          .where((sec) =>
              sec['name'].toLowerCase().contains(query.toLowerCase()) ||
              sec['section_code'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // --- UI DIALOGS ---
  void _showSectionForm([Map<String, dynamic>? section]) {
    final isEditing = section != null;
    final codeController = TextEditingController(text: section?['section_code']);
    final nameController = TextEditingController(text: section?['name']);
    final divController = TextEditingController(text: section?['division']);
    final subDivController = TextEditingController(text: section?['subdivision']);
    final phoneController = TextEditingController(text: section?['phone']);
    final addressController = TextEditingController(text: section?['address']);
    final latController = TextEditingController(text: section?['latitude']?.toString());
    final lngController = TextEditingController(text: section?['longitude']?.toString());
    bool isActive = section?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? "Edit Section" : "Add Section"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 20,
                runSpacing: 15,
                children: [
                  _buildField(codeController, "Section Code", 0.3),
                  _buildField(nameController, "Office Name", 0.3),
                  _buildField(divController, "Division", 0.3),
                  _buildField(subDivController, "Sub-Division", 0.3),
                  _buildField(phoneController, "Contact Phone", 0.3),
                  _buildField(latController, "Latitude", 0.15),
                  _buildField(lngController, "Longitude", 0.15),
                  _buildField(addressController, "Full Address", 0.63, maxLines: 2),
                  SizedBox(
                    width: 200,
                    child: CheckboxListTile(
                      title: const Text("Is Active"),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v!),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'section_code': codeController.text,
                  'name': nameController.text,
                  'division': divController.text,
                  'subdivision': subDivController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                  'latitude': double.tryParse(latController.text),
                  'longitude': double.tryParse(lngController.text),
                  'is_active': isActive,
                };
                if (isEditing) {
                  await _supabase.from('sections').update(payload).eq('section_id', section['section_id']);
                } else {
                  await _supabase.from('sections').insert(payload);
                }
                Navigator.pop(context);
                _fetchSections();
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Field Builder
  Widget _buildField(TextEditingController controller, String label, double widthFactor, {int maxLines = 1}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * widthFactor,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Future<void> _deleteSection(String id) async {
    try {
      await _supabase.from('sections').delete().eq('section_id', id);
      _fetchSections();
    } catch (e) {
      _showSnackBar("Cannot delete: Linked records exist.", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Section Management"),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showSectionForm(),
            icon: const Icon(Icons.add),
            label: const Text("Add Section"),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search by Name or Section Code...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterSections,
            ),
          ),
          
          // 2. DATA TABLE AREA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  // Separated Table Widget for Clarity
  Widget _buildDataTable() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // Vertical Scrolling
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Horizontal Scrolling
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Division')),
                  DataColumn(label: Text('Sub-Division')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _filteredSections.map((sec) {
                  return DataRow(cells: [
                    DataCell(Text(sec['section_code'] ?? '')),
                    DataCell(Text(sec['name'] ?? '')),
                    DataCell(Text(sec['division'] ?? '')),
                    DataCell(Text(sec['subdivision'] ?? '-')),
                    DataCell(Text(sec['phone'] ?? '-')),
                    DataCell(Icon(
                      sec['is_active'] ? Icons.check_circle : Icons.cancel,
                      color: sec['is_active'] ? Colors.green : Colors.red,
                    )),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showSectionForm(sec)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSection(sec['section_id'])),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}