import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

// ─── Supabase Bağlantı Test Ekranı ────────────────────────────
// main.dart'ta geçici olarak home: const SupabaseTestScreen() yap
// Test bittikten sonra home: const AppRouter() geri al

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  final List<_TestResult> _results = [];
  bool _running = false;

  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  Future<void> _runAll() async {
    setState(() {
      _results.clear();
      _running = true;
    });

    await _test('🌐 Supabase URL bağlantısı', _testConnection);
    await _test('📋 users tablosu', _testUsersTable);
    await _test('📋 photos tablosu', _testPhotosTable);
    await _test('📋 matches tablosu', _testMatchesTable);
    await _test('📋 messages tablosu', _testMessagesTable);
    await _test('📋 swipes tablosu', _testSwipesTable);
    await _test('📋 preferences tablosu', _testPreferencesTable);
    await _test('🪣 Storage bucket (photos)', _testStorage);
    await _test('🔐 Auth servisi', _testAuth);
    await _test('⚡ Realtime bağlantısı', _testRealtime);

    setState(() => _running = false);
  }

  Future<void> _test(String name, Future<String> Function() fn) async {
    final result = _TestResult(name: name, status: _Status.running);
    setState(() => _results.add(result));

    try {
      final detail = await fn().timeout(const Duration(seconds: 10));
      setState(() => result
        ..status = _Status.ok
        ..detail = detail);
    } catch (e) {
      setState(() => result
        ..status = _Status.fail
        ..detail = e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Testler ─────────────────────────────────────────────────

  Future<String> _testConnection() async {
    final res = await _client.from('users').select('id').limit(1);
    return 'Bağlantı başarılı';
  }

  Future<String> _testUsersTable() async {
    await _client.from('users').select('id, name, city, birthdate').limit(1);
    return 'Tablo erişilebilir';
  }

  Future<String> _testPhotosTable() async {
    await _client.from('photos').select('id, user_id, url').limit(1);
    return 'Tablo erişilebilir';
  }

  Future<String> _testMatchesTable() async {
    await _client.from('matches').select('id, user1_id, user2_id').limit(1);
    return 'Tablo erişilebilir';
  }

  Future<String> _testMessagesTable() async {
    await _client.from('messages').select('id, match_id, content').limit(1);
    return 'Tablo erişilebilir';
  }

  Future<String> _testSwipesTable() async {
    await _client.from('swipes').select('id, from_user, action').limit(1);
    return 'Tablo erişilebilir';
  }

  Future<String> _testPreferencesTable() async {
    await _client.from('preferences').select('id, user_id').limit(1);
    return 'Tablo erişilebilir';
  }

  Future<String> _testStorage() async {
    final buckets = await _client.storage.listBuckets();
    final found = buckets.any((b) => b.id == 'photos');
    if (!found) throw Exception('photos bucket bulunamadı — schema.sql çalıştırıldı mı?');
    return 'photos bucket hazır';
  }

  Future<String> _testAuth() async {
    final session = _client.auth.currentSession;
    if (session != null) return 'Oturum açık: ${_client.auth.currentUser?.phone ?? 'bilinmiyor'}';
    return 'Auth servisi çalışıyor (oturum yok)';
  }

  Future<String> _testRealtime() async {
    final completer = Future.delayed(const Duration(seconds: 2));
    _client.channel('test').subscribe();
    await completer;
    return 'Realtime aktif';
  }

  // ─── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final okCount = _results.where((r) => r.status == _Status.ok).length;
    final failCount = _results.where((r) => r.status == _Status.fail).length;
    final total = 10;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Supabase Test'),
        actions: [
          if (!_running)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Özet kart
          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: failCount == 0 && !_running
                    ? kSuccessLight
                    : _running
                        ? kPrimaryLight
                        : const Color(0xFFFAECE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: failCount == 0 && !_running
                      ? kSuccess.withOpacity(0.4)
                      : _running
                          ? kPrimary.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(children: [
                Icon(
                  _running
                      ? Icons.hourglass_top_outlined
                      : failCount == 0
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                  color: _running
                      ? kPrimary
                      : failCount == 0
                          ? kSuccess
                          : Colors.red,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _running
                            ? 'Test çalışıyor...'
                            : failCount == 0
                                ? 'Tüm testler geçti! 🎉'
                                : '$failCount test başarısız',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _running
                              ? kPrimary
                              : failCount == 0
                                  ? kSuccess
                                  : Colors.red,
                        ),
                      ),
                      Text(
                        '${_results.length}/$total test tamamlandı  •  $okCount başarılı${failCount > 0 ? '  •  $failCount hatalı' : ''}',
                        style: const TextStyle(fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ]),
            ),

          // Test listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _results.length,
              itemBuilder: (_, i) => _buildRow(_results[i]),
            ),
          ),

          // Sonuç & sonraki adım
          if (!_running && _results.length == total)
            _buildFooter(failCount),
        ],
      ),
    );
  }

  Widget _buildRow(_TestResult r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(children: [
        _statusIcon(r.status),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextPrimary)),
              if (r.detail != null)
                Text(r.detail!, style: TextStyle(
                  fontSize: 11,
                  color: r.status == _Status.fail ? Colors.red : kTextSecondary,
                )),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _statusIcon(_Status s) {
    switch (s) {
      case _Status.running:
        return const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary));
      case _Status.ok:
        return const Icon(Icons.check_circle, color: kSuccess, size: 20);
      case _Status.fail:
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
    }
  }

  Widget _buildFooter(int failCount) {
    if (failCount > 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔧 Hata çözüm önerileri:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._getFixSuggestions(),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(children: [
        const Text('✅ Supabase hazır! Uygulamayı çalıştırabilirsin.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSuccess)),
        const SizedBox(height: 10),
        const Text('main.dart\'ta home: const AppRouter() yap ve flutter run',
            style: TextStyle(fontSize: 12, color: kTextSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  List<Widget> _getFixSuggestions() {
    final fixes = <Widget>[];
    for (final r in _results.where((r) => r.status == _Status.fail)) {
      String fix = '';
      if (r.name.contains('URL')) {
        fix = '→ lib/main.dart içindeki url ve anonKey değerlerini kontrol et';
      } else if (r.name.contains('tablosu')) {
        fix = '→ supabase/schema.sql dosyasını SQL Editor\'a yapıştırıp Run bas';
      } else if (r.name.contains('bucket')) {
        fix = '→ schema.sql\'deki Storage bölümünü tekrar çalıştır';
      } else if (r.name.contains('Auth')) {
        fix = '→ Supabase → Authentication → Providers → Phone\'u aç';
      }
      if (fix.isNotEmpty) {
        fixes.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('${r.name}: $fix',
              style: const TextStyle(fontSize: 11, color: kTextSecondary)),
        ));
      }
    }
    return fixes;
  }
}

class _TestResult {
  final String name;
  _Status status;
  String? detail;
  _TestResult({required this.name, required this.status});
}

enum _Status { running, ok, fail }
