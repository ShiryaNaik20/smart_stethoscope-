import 'package:flutter/material.dart';
import 'screens/recording_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/patient_details_screen.dart';

void main() {
  runApp(const SmartStethoscopeApp());
}

class SmartStethoscopeApp extends StatelessWidget {
  const SmartStethoscopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Stethoscope',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // ✅ FIXED HERE (CardThemeData instead of CardTheme)
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

////////////////////////////////////////////////////////////
/// SPLASH SCREEN
////////////////////////////////////////////////////////////

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_heart, color: Colors.white, size: 90),
            SizedBox(height: 20),
            Text(
              "Smart Stethoscope",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "AI Health Monitoring",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HOME SCREEN
////////////////////////////////////////////////////////////

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Stethoscope"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// Dashboard Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.bluetooth, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Device Status: Connected",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Last Scan: Today"),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.green),
                        SizedBox(width: 8),
                        Text("AI Status: Active"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 35),

            buildModernButton(
              context,
              "Connect Device",
              Icons.bluetooth,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Device Connected (Demo Mode)"),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            buildModernButton(
              context,
              "Record Heart Sound",
              Icons.favorite,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PatientDetailsScreen(mode: "Heart"),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            buildModernButton(
              context,
              "Record Lung Sound",
              Icons.air,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PatientDetailsScreen(mode: "Lung"),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            buildModernButton(
              context,
              "View Reports",
              Icons.description,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// MODERN BUTTON
  ////////////////////////////////////////////////////////////

  Widget buildModernButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
