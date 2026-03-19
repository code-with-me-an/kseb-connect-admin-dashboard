import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfficersPage extends StatefulWidget {
  const OfficersPage({super.key});

  @override
  State<OfficersPage> createState() => _OfficersPageState();
}

class _OfficersPageState extends State<OfficersPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _officers = [];
  List<Map<String, dynamic>> _filteredOfficers = [];
  List<Map<String, dynamic>> _sections = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        _supabase.from('officers').select('*, sections(name, section_code)'),
        _supabase.from('sections').select('section_id, name, section_code'),
      ]);

      setState(() {
        _officers = List<Map<String, dynamic>>.from(results[0]);
        _filteredOfficers = _officers;
        _sections = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  void _filterOfficers(String query) {
    setState(() {
      _filteredOfficers = _officers.where((off) {
        final name = off['name'].toString().toLowerCase();
        final username = off['username'].toString().toLowerCase();
        final sectionCode = off['sections']?['section_code']?.toString().toLowerCase() ?? '';
        final sectionName = off['sections']?['name']?.toString().toLowerCase() ?? '';
        
        return name.contains(query.toLowerCase()) || 
               username.contains(query.toLowerCase()) ||
               sectionCode.contains(query.toLowerCase()) ||
               sectionName.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _deleteOfficer(String id) async {
    try {
      await _supabase.from('officers').delete().eq('officer_id', id);
      _showSnackBar("Officer removed", Colors.green);
      _fetchInitialData();
    } catch (e) {
      _showSnackBar("Delete failed: $e", Colors.red);
    }
  }

  void _showOfficerForm([Map<String, dynamic>? officer]) {
    final isEditing = officer != null;
    final nameController = TextEditingController(text: officer?['name']);
    final usernameController = TextEditingController(text: officer?['username']);
    final emailController = TextEditingController(text: officer?['email']);
    final mobileController = TextEditingController(text: officer?['mobile']);
    final passwordController = TextEditingController(); // Always empty initially for security
    String? selectedSectionId = officer?['section_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? "Edit Officer Details" : "Register New Officer"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildField(nameController, "Full Name", 0.27, Icons.person),
                  _buildField(usernameController, "Username", 0.27, Icons.alternate_email),
                  _buildField(emailController, "Email Address", 0.27, Icons.email),
                  _buildField(mobileController, "Mobile Number", 0.27, Icons.phone),
                  
                  // Password Field
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.27,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEditing ? "New Password (Leave blank to keep old)" : "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        helperText: isEditing ? "Only fill if changing password" : null,
                      ),
                    ),
                  ),

                  // Section Dropdown
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.27,
                    child: DropdownButtonFormField<String>(
                      value: selectedSectionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Assigned Section Office",
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
                // Validation
                if (!isEditing && passwordController.text.isEmpty) {
                  _showSnackBar("Password is required for new officers", Colors.orange);
                  return;
                }

                // Logic: Only hash and update password if it's not empty
                final Map<String, dynamic> payload = {
                  'name': nameController.text,
                  'username': usernameController.text,
                  'email': emailController.text,
                  'mobile': mobileController.text,
                  'section_id': selectedSectionId,
                };

                // Add hashed password to payload if provided
                if (passwordController.text.isNotEmpty) {
                  // This tells Supabase to use the PostgREST raw expression for crypt
                  payload['password'] = passwordController.text;
                }

                try {
                  if (isEditing) {
                    // Update: Note that Supabase client handles simple data. 
                    // To use 'crypt' specifically, we use an RPC or a Database Trigger.
                    // Assuming you have a trigger on the DB for hashing, or we use a custom RPC:
                    await _supabase.rpc('upsert_officer_with_hash', params: {
                      'p_officer_id': officer['officer_id'],
                      'p_name': payload['name'],
                      'p_username': payload['username'],
                      'p_email': payload['email'],
                      'p_mobile': payload['mobile'],
                      'p_section_id': payload['section_id'],
                      'p_password': passwordController.text.isEmpty ? null : passwordController.text,
                    });
                  } else {
                    await _supabase.rpc('upsert_officer_with_hash', params: {
                      'p_officer_id': null,
                      'p_name': payload['name'],
                      'p_username': payload['username'],
                      'p_email': payload['email'],
                      'p_mobile': payload['mobile'],
                      'p_section_id': payload['section_id'],
                      'p_password': passwordController.text,
                    });
                  }
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _fetchInitialData();
                  _showSnackBar("Officer saved successfully", Colors.green);
                } catch (e) {
                  _showSnackBar("Error saving officer: $e", Colors.red);
                }
              },
              child: const Text("Save Officer"),
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Officer Management"),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showOfficerForm(),
            icon: const Icon(Icons.person_add),
            label: const Text("Add New Officer"),
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
              onChanged: _filterOfficers,
              decoration: InputDecoration(
                hintText: "Search by Name, Username, or Section Code...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      _filterOfficers('');
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
                        itemCount: _filteredOfficers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final off = _filteredOfficers[index];
                          final section = off['sections'];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(off['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("@${off['username']} • ${off['mobile']}"),
                                Text("Assigned: ${section?['section_code']} - ${section?['name']}", 
                                     style: TextStyle(color: Colors.blue[700], fontSize: 13)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showOfficerForm(off)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteOfficer(off['officer_id'])),
                              ],
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