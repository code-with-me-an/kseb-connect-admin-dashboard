import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
          .where(
            (sec) =>
                sec['name'].toLowerCase().contains(query.toLowerCase()) ||
                sec['section_code'].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // --- UI DIALOGS ---
  void _showSectionForm([Map<String, dynamic>? section]) {
    final isEditing = section != null;

    final codeController = TextEditingController(
      text: section?['section_code'],
    );
    final nameController = TextEditingController(text: section?['name']);
    final divController = TextEditingController(text: section?['division']);
    final subDivController = TextEditingController(
      text: section?['subdivision'],
    );
    final phoneController = TextEditingController(text: section?['phone']);
    final addressController = TextEditingController(text: section?['address']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                _buildField(
                  addressController,
                  "Full Address",
                  0.63,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();

              // Move to Map Step
              _showMapPickerDialog(
                isEditing: isEditing,
                section: section,
                formData: {
                  'section_code': codeController.text,
                  'name': nameController.text,
                  'division': divController.text,
                  'subdivision': subDivController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                },
              );
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  void _showMapPickerDialog({
    required bool isEditing,
    Map<String, dynamic>? section,
    required Map<String, dynamic> formData,
  }) {
    LatLng selectedLocation = LatLng(
      section?['latitude'] ?? 11.2588, // Default: Kerala
      section?['longitude'] ?? 75.7804,
    );

    bool isActive = section?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Select Location"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Tap on map to select location",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                SizedBox(
                  height: 400,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: selectedLocation,
                        initialZoom: 13,
                        onTap: (tapPosition, latlng) {
                          setDialogState(() {
                            selectedLocation = latlng;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selectedLocation,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 📍 Latitude & Longitude Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text(
                          "Lat: ${selectedLocation.latitude.toStringAsFixed(6)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Text(
                        "Lng: ${selectedLocation.longitude.toStringAsFixed(6)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // Is Active (Text left, checkbox right)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text("Is Active", style: TextStyle(fontSize: 16)),
                      Checkbox(
                        value: isActive,
                        onChanged: (v) => setDialogState(() => isActive = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                _showSectionForm(section);
              },
              child: const Text("Back"),
            ),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  ...formData,
                  'latitude': selectedLocation.latitude,
                  'longitude': selectedLocation.longitude,
                  'is_active': isActive,
                };

                if (isEditing) {
                  await _supabase
                      .from('sections')
                      .update(payload)
                      .eq('section_id', section!['section_id']);
                } else {
                  await _supabase.from('sections').insert(payload);
                }

                Navigator.of(context, rootNavigator: true).pop();
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
  Widget _buildField(
    TextEditingController controller,
    String label,
    double widthFactor, {
    int maxLines = 1,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * widthFactor,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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

  void _showSnackBar(String message, Color color) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));

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
                  return DataRow(
                    cells: [
                      DataCell(Text(sec['section_code'] ?? '')),
                      DataCell(Text(sec['name'] ?? '')),
                      DataCell(Text(sec['division'] ?? '')),
                      DataCell(Text(sec['subdivision'] ?? '-')),
                      DataCell(Text(sec['phone'] ?? '-')),
                      DataCell(
                        Icon(
                          sec['is_active'] ? Icons.check_circle : Icons.cancel,
                          color: sec['is_active'] ? Colors.green : Colors.red,
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showSectionForm(sec),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteSection(sec['section_id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
