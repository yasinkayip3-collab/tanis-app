import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

export 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TanisApp());
}

class TanisApp extends StatelessWidget {
  const TanisApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanış',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kPrimary),
          iconTheme: IconThemeData(color: kTextPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
          hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
        ),
      ),
      home: const _InitScreen(),
    );
  }
}

class _InitScreen extends StatefulWidget {
  const _InitScreen();
  @override
  State<_InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<_InitScreen> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Supabase.initialize(
        url: 'https://krywpgqgarkyhltphqge.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyeXdwZ3FnYXJreWhsdHBocWdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NzAyMDMsImV4cCI6MjA5ODE0NjIwM30.jdm4OofdZM44IHR0qb9MezODuqD3xYeWVWmFF4geH_8',
      );
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_outlined, size: 64, color: kPrimary),
          const SizedBox(height: 16),
          const Text('Bağlantı hatası', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('İnternet bağlantını kontrol et', style: TextStyle(color: kTextSecondary)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () => setState(() { _error = null; _init(); }),
              child: const Text('Tekrar dene'),
            ),
          ),
        ])),
      );
    }
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('tanış', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: kPrimary, letterSpacing: -1)),
          SizedBox(height: 24),
          CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
          SizedBox(height: 16),
          Text('Yükleniyor...', style: TextStyle(color: kTextSecondary, fontSize: 13)),
        ])),
      );
    }
    return const AppRouter();
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: kPrimary)),
          );
        }
        final session = snapshot.data!.session;
        if (session == null) return const AuthScreen();
        return const HomeScreen();
      },
    );
  }
}
