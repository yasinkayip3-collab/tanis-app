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
    if (!email.contains('@') || pass.length < 6) { _snack('Geçerli e-posta ve en az 6 karakterli şifre gir'); return; }
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      if (_isLogin) {
        await client.auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await client.auth.signUp(email: email, password: pass);
        if (res.user != null && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
          return;
        }
        _snack('E-posta adresini doğrula, sonra giriş yap');
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login')) msg = 'E-posta veya şifre hatalı';
      else if (msg.contains('already registered')) msg = 'Bu e-posta zaten kayıtlı';
      _snack(msg);
    } catch (_) { _snack('Bağlantı hatası'); }
    if (mounted) setState(() => _loading = false);
  }

  void _snack(String msg) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 40),
      const Text('tanış', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: kPrimary, letterSpacing: -1.2)),
      const SizedBox(height: 6),
      const Text('Yeni insanlarla tanış, arkadaşlık kur', style: TextStyle(color: kTextSecondary)),
      const SizedBox(height: 40),
      Container(
        decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder, width: 0.5)),
        padding: const EdgeInsets.all(4),
        child: Row(children: [_tab('Giriş yap', _isLogin, () => setState(() => _isLogin = true)), _tab('Kayıt ol', !_isLogin, () => setState(() => _isLogin = false))])),
      const SizedBox(height: 24),
      const Text('E-posta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)),
      const SizedBox(height: 6),
      TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(hintText: 'ornek@mail.com', prefixIcon: Icon(Icons.mail_outline, size: 18, color: kTextSecondary))),
      const SizedBox(height: 14),
      const Text('Şifre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)),
      const SizedBox(height: 6),
      TextField(controller: _passCtrl, obscureText: !_showPass,
        decoration: InputDecoration(hintText: 'Şifre', prefixIcon: const Icon(Icons.lock_outline, size: 18, color: kTextSecondary),
          suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: kTextSecondary), onPressed: () => setState(() => _showPass = !_showPass))),
        onSubmitted: (_) => _submit()),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isLogin ? 'Giriş yap' : 'Hesap oluştur'))),
      const SizedBox(height: 32),
      Center(child: Text('18 yaşından büyük olman gerekiyor', style: TextStyle(fontSize: 12, color: kTextSecondary.withOpacity(0.6)))),
    ]))));

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9)),
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? kTextPrimary : kTextSecondary)))));
}
