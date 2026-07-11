import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/supabase_service.dart';

// ─── Profil Ana Ekranı ─────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await SupabaseService.getProfile(
          SupabaseService.currentUser!.id);
      setState(() { _profile = p; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int get _completionScore {
    if (_profile == null) return 0;
    int score = 0;
    if ((_profile!['name'] ?? '').isNotEmpty) score += 20;
    if ((_profile!['bio'] ?? '').length > 20) score += 20;
    final photos = _profile!['photos'] as List? ?? [];
    if (photos.isNotEmpty) score += 20;
    if (photos.length >= 3) score += 10;
    final interests = _profile!['user_interests'] as List? ?? [];
    if (interests.length >= 3) score += 15;
    if (interests.length >= 6) score += 15;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Tavsiyeler',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProfileTipsScreen(score: _completionScore))),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile ?? {})));
              _loadProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async => await SupabaseService.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [
                  _buildHero(),
                  _buildStats(),
                  _buildInfoSection(),
                  _buildInterests(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }

  Widget _buildHero() {
    final name = _profile?['name'] ?? '';
    final city = _profile?['city'] ?? '';
    final birthdate = _profile?['birthdate'];
    final age = _calcAge(birthdate);
    final score = _completionScore;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(children: [
        Stack(children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: kPrimaryLight,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: kPrimary),
              ),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: kPrimary, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: kTextPrimary)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.location_on_outlined, size: 14, color: kTextSecondary),
          const SizedBox(width: 3),
          Text('$city • $age yaş', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Profil tamamlanma', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          Text('%$score', style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: kPrimaryLight,
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        _statCard('Beğeni', '—'),
        const SizedBox(width: 10),
        _statCard('Eşleşme', '—'),
        const SizedBox(width: 10),
        _statCard('Görüntüleme', '—'),
      ]),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: kTextPrimary)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
        ]),
      ),
    );
  }

  Widget _buildInfoSection() {
    final bio = _profile?['bio'] ?? '';
    final prefsList = _profile?['preferences'] as List?;
    final prefs = (prefsList != null && prefsList.isNotEmpty) ? prefsList.first as Map : {};
    final purpose = prefs['purpose'] ?? '—';
    final seeking = prefs['seeking_gender'] ?? '—';
    final ageMin = prefs['age_min'] ?? 18;
    final ageMax = prefs['age_max'] ?? 35;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(children: [
        _sectionHeader('Temel bilgiler', onEdit: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile ?? {})));
          _loadProfile();
        }),
        if (bio.isNotEmpty) _infoRow(Icons.person_outline, 'Hakkında', bio),
        _infoRow(Icons.my_location_outlined, 'Amaç', purpose),
        _infoRow(Icons.favorite_outline, 'Arıyorum', '$seeking • $ageMin–$ageMax yaş'),
      ]),
    );
  }

  Widget _buildInterests() {
    final interests = (_profile?['user_interests'] as List? ?? [])
        .map((i) => i['interest']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('İlgi alanları', onEdit: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile ?? {})));
          _loadProfile();
        }),
        if (interests.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text('Henüz ilgi alanı eklenmedi', style: TextStyle(color: kTextSecondary, fontSize: 13)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Wrap(
              spacing: 7, runSpacing: 7,
              children: interests.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPrimary.withOpacity(0.3), width: 0.5),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 12, color: kPrimaryDark, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),
      ]),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary, letterSpacing: 0.5)),
        const Spacer(),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: const Text('Düzenle', style: TextStyle(fontSize: 12, color: kPrimary)),
          ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: kBorder, width: 0.5))),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: kPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: kTextPrimary)),
        ])),
      ]),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null || !mounted) return;
    try {
      await SupabaseService.uploadPhoto(img.path, 0);
      _loadProfile();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf yüklenemedi')));
    }
  }

  int _calcAge(String? b) {
    if (b == null) return 0;
    final dt = DateTime.tryParse(b);
    if (dt == null) return 0;
    final now = DateTime.now();
    int age = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) age--;
    return age;
  }
}

// ─── Tavsiyeler Ekranı ─────────────────────────────────────────
class ProfileTipsScreen extends StatelessWidget {
  final int score;
  const ProfileTipsScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final tips = _buildTips(score);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Profil tavsiyeleri')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TipCard(tip: tips[i]),
      ),
    );
  }

  List<_Tip> _buildTips(int score) => [
    _Tip(
      icon: Icons.camera_alt_outlined,
      color: kPrimary,
      bgColor: kPrimaryLight,
      title: 'Daha fazla fotoğraf ekle',
      body: '3+ fotoğraflı profiller %60 daha fazla eşleşme alıyor. Net, gülümseyen bir yüz fotoğrafı en iyi sonucu veriyor.',
      action: score < 70 ? 'Fotoğraf ekle' : null,
    ),
    _Tip(
      icon: Icons.edit_outlined,
      color: kSuccess,
      bgColor: kSuccessLight,
      title: 'Biyografini genişlet',
      body: '3–4 cümlelik özgün bir anlatı seni öne çıkarır. Hobilerin, hayallerin ve mizahından bahset.',
      action: 'Biyografi düzenle',
    ),
    _Tip(
      icon: Icons.star_outline,
      color: const Color(0xFFBA7517),
      bgColor: const Color(0xFFFAEEDA),
      title: 'İlgi alanı ekle',
      body: 'Ortak ilgi alanı olan kişiler 2 kat daha fazla sohbet başlatıyor. En az 5–8 ilgi alanı seçmeni öneririz.',
      action: 'İlgi alanları düzenle',
    ),
    _Tip(
      icon: Icons.access_time_outlined,
      color: kPrimary,
      bgColor: kPrimaryLight,
      title: 'Aktif saatlerde giriş yap',
      body: 'Şehrinde en aktif saatler 20:00–23:00 arası. Bu saatlerde giriş yaparsan profil görünürlüğün önemli ölçüde artar.',
    ),
    _Tip(
      icon: Icons.thumb_up_outlined,
      color: kSuccess,
      bgColor: kSuccessLight,
      title: 'İlk mesajı sen gönder',
      body: 'Eşleşmeden sonra 24 saat içinde mesaj gönderen kullanıcılar %3 kat daha fazla karşılıklı sohbet yaşıyor.',
    ),
  ];
}

class _Tip {
  final IconData icon;
  final Color color, bgColor;
  final String title, body;
  final String? action;
  const _Tip({required this.icon, required this.color, required this.bgColor,
    required this.title, required this.body, this.action});
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  const _TipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: tip.bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(tip.icon, size: 18, color: tip.color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tip.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextPrimary)),
          const SizedBox(height: 5),
          Text(tip.body, style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.45)),
          if (tip.action != null) ...[
            const SizedBox(height: 8),
            Text(tip.action!, style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
          ],
        ])),
      ]),
    );
  }
}

// ─── Profil Düzenleme Ekranı ───────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late String _city;
  late String _purpose;
  late String _seekingGender;
  late double _ageMin, _ageMax;
  late Set<String> _interests;
  bool _saving = false;

  final _cities = ['Samsun','İstanbul','Ankara','İzmir','Bursa','Antalya','Trabzon','Konya','Gaziantep','Adana'];
  final _allInterests = ['Müzik','Spor','Seyahat','Sinema','Oyun','Yemek','Sanat','Teknoloji','Kitap','Dans','Doğa','Fotoğrafçılık','Yoga','Bisiklet'];

  @override
  void initState() {
    super.initState();
    final prefsList = widget.profile['preferences'] as List?;
    final prefs = (prefsList != null && prefsList.isNotEmpty) ? prefsList.first as Map : {};
    _nameCtrl = TextEditingController(text: widget.profile['name'] ?? '');
    _bioCtrl  = TextEditingController(text: widget.profile['bio'] ?? '');
    _city     = widget.profile['city'] ?? 'Samsun';
    _purpose  = prefs['purpose'] ?? 'Arkadaşlık';
    _seekingGender = prefs['seeking_gender'] ?? 'Fark etmez';
    _ageMin   = (prefs['age_min'] ?? 18).toDouble();
    _ageMax   = (prefs['age_max'] ?? 35).toDouble();
    final raw = widget.profile['user_interests'] as List? ?? [];
    _interests = raw.map((i) => i['interest']?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.createProfile(
        name: _nameCtrl.text.trim(),
        birthdate: DateTime.tryParse(widget.profile['birthdate'] ?? '') ?? DateTime(2000),
        gender: widget.profile['gender'] ?? 'Belirtilmedi',
        city: _city,
        bio: _bioCtrl.text.trim(),
      );
      await SupabaseService.savePreferences(
        seekingGender: _seekingGender,
        ageMin: _ageMin.toInt(),
        ageMax: _ageMax.toInt(),
        purpose: _purpose,
      );
      await SupabaseService.saveInterests(_interests.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi'), backgroundColor: kSuccess));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi, tekrar dene')));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Profili düzenle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
                : const Text('Kaydet', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _card(children: [
            _fieldLabel('Ad soyad'),
            _textField(_nameCtrl, 'Adın ne?'),
            const SizedBox(height: 12),
            _fieldLabel('Şehir'),
            _dropdown(_cities, _city, (v) => setState(() => _city = v!)),
            const SizedBox(height: 12),
            _fieldLabel('Hakkında'),
            _textArea(_bioCtrl, 'Kendini kısaca tanıt...'),
          ]),
          const SizedBox(height: 12),
          _card(children: [
            _fieldLabel('Arıyorum'),
            _segmented(['Kadın','Erkek','Fark etmez'], _seekingGender,
                (v) => setState(() => _seekingGender = v)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _fieldLabel('Yaş aralığı'),
              Text('${_ageMin.toInt()} – ${_ageMax.toInt()}',
                  style: const TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w500)),
            ]),
            RangeSlider(
              values: RangeValues(_ageMin, _ageMax),
              min: 18, max: 60, divisions: 42,
              activeColor: kPrimary, inactiveColor: kPrimaryLight,
              onChanged: (v) => setState(() { _ageMin = v.start; _ageMax = v.end; }),
            ),
            _fieldLabel('Amaç'),
            _segmented(['Arkadaşlık','İlişki','Gezmek'], _purpose,
                (v) => setState(() => _purpose = v)),
          ]),
          const SizedBox(height: 12),
          _card(children: [
            _fieldLabel('İlgi alanları  •  ${_interests.length} seçildi'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7, runSpacing: 7,
              children: _allInterests.map((tag) {
                final sel = _interests.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() => sel ? _interests.remove(tag) : _interests.add(tag)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? kPrimaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? kPrimary : kBorder, width: sel ? 1.5 : 0.5),
                    ),
                    child: Text(tag, style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                      color: sel ? kPrimaryDark : kTextSecondary,
                    )),
                  ),
                );
              }).toList(),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Değişiklikleri kaydet'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton(
              onPressed: _confirmDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hesabı sil'),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text('Hesabını silmek istediğine emin misin? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SupabaseService.signOut();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)),
  );

  Widget _textField(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: kTextSecondary)),
  );

  Widget _textArea(TextEditingController c, String hint) => TextField(
    controller: c, maxLines: 3, maxLength: 150,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: kTextSecondary), alignLabelWithHint: true),
  );

  Widget _dropdown(List<String> items, String value, ValueChanged<String?> onChanged) =>
    DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: const InputDecoration(),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );

  Widget _segmented(List<String> opts, String sel, ValueChanged<String> onChanged) =>
    Container(
      decoration: BoxDecoration(
        color: kBackground, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(children: opts.map((o) {
        final active = o == sel;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(o, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? Colors.white : kTextSecondary)),
          ),
        ));
      }).toList()),
    );
}
