import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLogin = true, _loading = false, _showPass = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (!email.contains('@')) { _snack('Geçerli bir e-posta gir'); return; }
    if (pass.length < 6) { _snack('Şifre en az 6 karakter olmalı'); return; }
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      if (_isLogin) {
        // Giriş
        final res = await client.auth.signInWithPassword(email: email, password: pass);
        if (res.user == null && mounted) {
          _snack('Giriş başarısız');
        }
        // Başarılıysa AppRouter otomatik HomeScreen'e yönlendirir
      } else {
        // Kayıt
        final res = await client.auth.signUp(email: email, password: pass);
        if (res.user != null && mounted) {
          // Profil kurulumuna git
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
            (route) => false,
          );
          return;
        } else if (mounted) {
          _snack('E-postanı doğrula, sonra giriş yap');
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login')) msg = 'E-posta veya şifre hatalı';
      else if (msg.contains('already registered')) msg = 'Bu e-posta zaten kayıtlı, giriş yap';
      else if (msg.contains('not confirmed')) msg = 'E-postanı doğrula';
      _snack(msg);
    } catch (e) {
      _snack('Bağlantı hatası: ${e.toString()}');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 40),
      const Text('tanış', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: kPrimary, letterSpacing: -1.2)),
      const SizedBox(height: 6),
      const Text('Yeni insanlarla tanış, arkadaşlık kur', style: TextStyle(color: kTextSecondary, fontSize: 15)),
      const SizedBox(height: 40),

      // Giriş / Kayıt tab
      Container(
        decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder, width: 0.5)),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          _tab('Giriş yap', _isLogin, () => setState(() => _isLogin = true)),
          _tab('Kayıt ol', !_isLogin, () => setState(() => _isLogin = false)),
        ])),
      const SizedBox(height: 28),

      // E-posta
      const Text('E-posta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: const InputDecoration(
          hintText: 'ornek@mail.com',
          prefixIcon: Icon(Icons.mail_outline, size: 18, color: kTextSecondary),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderSide: BorderSide(color: kBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimary, width: 1.5)),
        )),
      const SizedBox(height: 14),

      // Şifre
      const Text('Şifre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: _passCtrl,
        obscureText: !_showPass,
        decoration: InputDecoration(
          hintText: _isLogin ? 'Şifreni gir' : 'En az 6 karakter',
          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: kTextSecondary),
          suffixIcon: IconButton(
            icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: kTextSecondary),
            onPressed: () => setState(() => _showPass = !_showPass)),
          filled: true, fillColor: Colors.white,
          border: const OutlineInputBorder(borderSide: BorderSide(color: kBorder, width: 0.5)),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kBorder, width: 0.5)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kPrimary, width: 1.5)),
        ),
        onSubmitted: (_) => _submit()),
      const SizedBox(height: 24),

      // Buton
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isLogin ? 'Giriş yap' : 'Hesap oluştur', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
      const SizedBox(height: 32),
      Center(child: Text('18 yaşından büyük olman gerekiyor',
          style: TextStyle(fontSize: 12, color: kTextSecondary.withOpacity(0.6)))),
    ]))));

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,2))] : null),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? kTextPrimary : kTextSecondary)))));
}
