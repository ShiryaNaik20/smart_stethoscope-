// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'screens/mode_selection_screen.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Lock to portrait
//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   // Status bar style
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ),
//   );

//   runApp(const AcuBeatApp());
// }

// class AcuBeatApp extends StatelessWidget {
//   const AcuBeatApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'AcuBeat',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         fontFamily: 'Roboto',
//       ),
//       home: const ModeSelectionScreen(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'screens/mode_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AcuBeat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: ModeSelectionScreen(), // Changed from LoginScreen
    );
  }
}