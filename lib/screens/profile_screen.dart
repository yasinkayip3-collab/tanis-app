import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String,dynamic>? _profile;
  bool _loading = true;
  final _client = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = _client.auth.currentUser?.id ?? '';
      final res = await _client.from('users').select('*, photos(*), user_interests(*), preferences(*)').eq('id', uid).single();
      setState(() { _profile = res; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  int _age(String? b) { if(b==null)return 0; final d=DateTime.tryParse(b); if(d==null)return 0; final n=DateTime.now(); int a=n.year-d.year; if(n.month<d.month||(n.month==d.month&&n.day<d.day))a--; return a; }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null || !mounted) return;
    try {
      final uid = _client.auth.currentUser!.id;
      final bytes = await img.readAsBytes();
      final path = '$uid/photo_0.jpg';
      await _client.storage.from('photos').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = _client.storage.from('photos').getPublicUrl(path);
      await _client.from('photos').upsert({'user_id': uid, 'url': url, 'order': 0, 'is_profile': true});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name']?.toString() ?? '';
    final city = _profile?['city']?.toString() ?? '';
    final bio  = _profile?['bio']?.toString() ?? '';
    final age  = _age(_profile?['birthdate']?.toString());
    final interests = (_profile?['user_interests'] as List? ?? []).map((i) => i['interest']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    final photos = _profile?['photos'] as List? ?? [];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
            _load();
          }),
          IconButton(icon: const Icon(Icons.logout_outlined), onPressed: () async {
            await _client.auth.signOut();
          }),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(color: kPrimary, onRefresh: _load, child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: [
                // Hero
                Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 24, 16, 20), child: Column(children: [
                  Stack(children: [
                    photos.isNotEmpty
                        ? CircleAvatar(radius: 44, backgroundImage: NetworkImage(photos[0]['url']?.toString() ?? ''))
                        : CircleAvatar(radius: 44, backgroundColor: kPrimaryLight,
                            child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: kPrimary))),
                    Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickPhoto,
                      child: Container(width: 26, height: 26,
                        decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white)))),
                  ]),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: kTextPrimary)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: kTextSecondary),
                    const SizedBox(width: 3),
                    Text('$city  •  $age yaş', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                  ]),
                  if (bio.isNotEmpty) ...[const SizedBox(height: 10), Text(bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.4))],
                ])),
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(color: Colors.white, padding: const EdgeInsets.all(16), width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('İLGİ ALANLARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 7, runSpacing: 7, children: interests.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: kPrimary.withOpacity(0.3), width: 0.5)),
                      child: Text(t, style: const TextStyle(fontSize: 12, color: kPrimaryDark, fontWeight: FontWeight.w500)))).toList()),
                  ])),
                ],
                const SizedBox(height: 24),
              ]))));
  }
}
