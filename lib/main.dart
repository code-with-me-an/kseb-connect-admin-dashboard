import 'package:flutter/material.dart';
import 'package:kseb_connect_admin_dashboard/screens/admin_login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/dashboard_overview.dart';
import 'screens/sections_page.dart';
import 'screens/officers_page.dart';
import 'screens/consumers_page.dart';

// Ensure your main function is async to handle initialization
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    runApp(const KsebConnectAdminApp());
  } catch (e) {
    // This will print the error to your terminal/browser console
    debugPrint("Initialization Error: $e");
  }
}

class KsebConnectAdminApp extends StatelessWidget {
  const KsebConnectAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KSEB Connect Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // A professional blue theme
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const AdminDashboard();
    } else {
      return const AdminLoginScreen();
    }
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // Placeholder screens.
  // We will replace these with actual files (like create_section_page.dart) later.
  final List<Widget> _screens = [
    const DashboardOverview(),
    const SectionsPage(),
    const OfficersPage(),
    const ConsumersPage(),
  ];
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Are you sure you want to exit the admin dashboard?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            color: Colors.blueGrey[900],
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Colors.transparent,
                    unselectedIconTheme: const IconThemeData(
                      color: Colors.white70,
                    ),
                    selectedIconTheme: const IconThemeData(
                      color: Colors.lightBlueAccent,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Colors.white70,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.domain_outlined),
                        selectedIcon: Icon(Icons.domain),
                        label: Text('Sections'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.badge_outlined),
                        selectedIcon: Icon(Icons.badge),
                        label: Text('Officers'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text('Consumers'),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.redAccent,
                    ),
                    tooltip: "Logout",
                    onPressed: _confirmLogout,
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
