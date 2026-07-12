import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/supabase_service.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin   = true;   // true=giriş, false=kayıt
  bool _loading   = false;
  bool _showPass  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── Giriş ────────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // AppRouter otomatik yönlendirir
    } on AuthException catch (e) {
      _showError(_authError(e.message));
    } catch (_) {
      _showError('Bağlantı hatası, tekrar dene');
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─── Kayıt ────────────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (res.user != null && mounted) {
        // Yeni kullanıcı → profil kurulumuna gönder
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
      } else if (mounted) {
        // E-posta doğrulama gerekiyorsa
        _showInfo('E-posta adresine doğrulama linki gönderildi. Kontrol et!');
      }
    } on AuthException catch (e) {
      _showError(_authError(e.message));
    } catch (_) {
      _showError('Kayıt başarısız, tekrar dene');
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─── Şifremi unuttum ──────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Önce e-posta adresini gir');
      return;
    }
    try {
      await SupabaseService.resetPassword(email);
      if (mounted) _showInfo('Şifre sıfırlama linki gönderildi!');
    } catch (_) {
      _showError('Gönderilemedi, e-postayı kontrol et');
    }
  }

  bool _validate() {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;
    if (email.isEmpty || !email.contains('@')) {
      _showError('Geçerli bir e-posta gir'); return false;
    }
    if (pass.length < 6) {
      _showError('Şifre en az 6 karakter olmalı'); return false;
    }
    return true;
  }

  String _authError(String msg) {
    if (msg.contains('Invalid login')) return 'E-posta veya şifre hatalı';
    if (msg.contains('already registered')) return 'Bu e-posta zaten kayıtlı';
    if (msg.contains('Email not confirmed')) return 'E-postanı doğrula, ardından giriş yap';
    if (msg.contains('weak')) return 'Şifre çok zayıf, daha güçlü bir şifre seç';
    return msg;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600));
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kSuccess));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Logo
              const Text('tanış',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                      color: kPrimary, letterSpacing: -1.2)),
              const SizedBox(height: 8),
              const Text('Yeni insanlarla tanış, arkadaşlık kur',
                  style: TextStyle(fontSize: 15, color: kTextSecondary)),
              const SizedBox(height: 40),

              // Tab — Giriş / Kayıt
              _buildTabToggle(),
              const SizedBox(height: 28),

              // E-posta
              _label('E-posta'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'ornek@mail.com',
                  prefixIcon: Icon(Icons.mail_outline, size: 18, color: kTextSecondary),
                ),
              ),
              const SizedBox(height: 14),

              // Şifre
              _label('Şifre'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: !_showPass,
                decoration: InputDecoration(
                  hintText: _isLogin ? 'Şifreni gir' : 'En az 6 karakter',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: kTextSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18, color: kTextSecondary),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                onSubmitted: (_) => _isLogin ? _signIn() : _signUp(),
              ),
              const SizedBox(height: 8),

              // Şifremi unuttum (sadece giriş modunda)
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32)),
                    child: const Text('Şifremi unuttum',
                        style: TextStyle(fontSize: 13, color: kPrimary)),
                  ),
                ),
              const SizedBox(height: 20),

              // Ana buton
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_isLogin ? _signIn : _signUp),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isLogin ? 'Giriş yap' : 'Hesap oluştur'),
                ),
              ),
              const SizedBox(height: 32),

              // Alt bilgi
              Center(
                child: Text(
                  '18 yaşından büyük olman gerekiyor',
                  style: TextStyle(fontSize: 12, color: kTextSecondary.withOpacity(0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _tab('Giriş yap', _isLogin, () => setState(() => _isLogin = true)),
        _tab('Kayıt ol', !_isLogin, () => setState(() => _isLogin = false)),
      ]),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? kTextPrimary : kTextSecondary,
            )),
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary));
}
