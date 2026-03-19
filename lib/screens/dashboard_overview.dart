import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  bool _isLoading = true;
  int _complaints = 0;
  int _users = 0;
  int _sections = 0;
  int _officers = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final supabase = Supabase.instance.client;

      // Running counts in parallel for speed
      final results = await Future.wait([
        supabase.from('complaints').count(),
        supabase.from('users').count(),
        supabase.from('sections').count(),
        supabase.from('officers').count(),
      ]);

      setState(() {
        _complaints = results[0];
        _users = results[1];
        _sections = results[2];
        _officers = results[3];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Database Analysis", 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 24),
          
          // Grid of Stat Cards
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard("Total Complaints", _complaints.toString(), Icons.report_problem, Colors.orange),
                _buildStatCard("Registered Users", _users.toString(), Icons.people, Colors.blue),
                _buildStatCard("Section Offices", _sections.toString(), Icons.account_balance, Colors.green),
                _buildStatCard("Active Officers", _officers.toString(), Icons.badge, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}