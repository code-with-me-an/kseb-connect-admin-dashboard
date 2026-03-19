import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumersPage extends StatefulWidget {
  const ConsumersPage({super.key});

  @override
  State<ConsumersPage> createState() => _ConsumersPageState();
}

class _ConsumersPageState extends State<ConsumersPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _consumers = [];
  List<Map<String, dynamic>> _filteredConsumers = [];
  List<Map<String, dynamic>> _sections = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _supabase.from('consumer_connections').select('*, sections(name, section_code)'),
        _supabase.from('sections').select('section_id, name, section_code'),
      ]);

      setState(() {
        _consumers = List<Map<String, dynamic>>.from(results[0]);
        _filteredConsumers = _consumers;
        _sections = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _filterConsumers(String query) {
    setState(() {
      _filteredConsumers = _consumers.where((cons) {
        final name = (cons['name'] ?? '').toString().toLowerCase();
        final number = cons['consumer_number'].toString().toLowerCase();
        final mobile = (cons['mobile_number'] ?? '').toString().toLowerCase();
        final section = cons['sections']?['name']?.toString().toLowerCase() ?? '';
        
        return name.contains(query.toLowerCase()) || 
               number.contains(query.toLowerCase()) ||
               mobile.contains(query.toLowerCase()) ||
               section.contains(query.toLowerCase());
      }).toList();
    });
  }

  // --- HELPER FUNCTION FOR MOBILE FORMATTING ---
  String _formatMobile(String phone) {
    String cleaned = phone.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return cleaned;
    
    // If it doesn't start with +91, add it
    if (!cleaned.startsWith('+91')) {
      // If user typed 91 without +, add +
      if (cleaned.startsWith('91') && cleaned.length > 10) {
        return '+$cleaned';
      }
      return '+91$cleaned';
    }
    return cleaned;
  }

  void _showConsumerForm([Map<String, dynamic>? consumer]) {
    final isEditing = consumer != null;
    final nameController = TextEditingController(text: consumer?['name']);
    final numberController = TextEditingController(text: consumer?['consumer_number']);
    final mobileController = TextEditingController(text: consumer?['mobile_number']);
    String? selectedSectionId = consumer?['section_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? "Edit Consumer Connection" : "Register New Consumer"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildField(nameController, "Consumer Name", 0.27, Icons.person),
                  _buildField(numberController, "Consumer Number (13 Digits)", 0.27, Icons.numbers),
                  _buildField(mobileController, "Mobile Number (e.g. 98765...)", 0.27, Icons.phone_android),
                  
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.27,
                    child: DropdownButtonFormField<String>(
                      value: selectedSectionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Assign Section Office",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: _sections.map((sec) {
                        return DropdownMenuItem<String>(
                          value: sec['section_id'],
                          child: Text("${sec['section_code']} - ${sec['name']}"),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedSectionId = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () async {
                // APPLY FORMATTING LOGIC HERE
                String formattedMobile = _formatMobile(mobileController.text);

                final payload = {
                  'name': nameController.text,
                  'consumer_number': numberController.text,
                  'mobile_number': formattedMobile, // Using formatted mobile
                  'section_id': selectedSectionId,
                };

                try {
                  if (isEditing) {
                    await _supabase.from('consumer_connections').update(payload).eq('consumer_id', consumer['consumer_id']);
                  } else {
                    await _supabase.from('consumer_connections').insert(payload);
                  }
                  Navigator.pop(context);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text("Save Connection"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, double widthFactor, IconData icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * widthFactor,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consumer Connections"),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showConsumerForm(),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text("Add New Consumer"),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterConsumers,
              decoration: InputDecoration(
                hintText: "Search by Name, Consumer Number, Mobile, or Section...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      _filterConsumers('');
                    }) 
                  : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      child: ListView.separated(
                        itemCount: _filteredConsumers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cons = _filteredConsumers[index];
                          final sec = cons['sections'];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.amber,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(cons['name'] ?? 'Unnamed Consumer', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ID: ${cons['consumer_number']} • Mob: ${cons['mobile_number'] ?? 'N/A'}"),
                                Text("Section: ${sec?['section_code']} - ${sec?['name']}", 
                                     style: TextStyle(color: Colors.blue[700], fontSize: 13)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showConsumerForm(cons),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}