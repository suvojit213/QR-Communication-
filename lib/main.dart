import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/generate_qr_screen.dart';
import 'screens/select_zip_screen.dart';
import 'screens/settings_screen.dart';
import 'provider/file_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FileProvider(),
      child: MaterialApp(
        title: 'QRBridge',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GenerateQRScreen(),
    const SelectZipScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code),
                label: 'Generate',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_zip),
                label: 'Select ZIP',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}