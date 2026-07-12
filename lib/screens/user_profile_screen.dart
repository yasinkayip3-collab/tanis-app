import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/supabase_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialData;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await SupabaseService.getProfile(widget.userId);
      setState(() { _profile = p; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String get _name => _profile?['name'] ?? '';
  String get _city => _profile?['city'] ?? '';
  String get _bio  => _profile?['bio']  ?? '';
  int    get _age  => _calcAge(_profile?['birthdate']);

  List<String> get _interests => (_profile?['user_interests'] as List? ?? [])
      .map<String>((i) => (i as Map)['interest']?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();

  List<Map<String, dynamic>> get _photos =>
      List<Map<String, dynamic>>.from(_profile?['photos'] ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(children: [
                    _buildInfo(),
                    if (_photos.isNotEmpty) _buildPhotos(),
                    if (_interests.isNotEmpty) _buildInterests(),
                    _buildActions(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ],
            ),
    );
  }

  // ─── Fotoğraflı AppBar ────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: kPrimary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: kTextPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, size: 18, color: kTextPrimary),
          ),
          onPressed: _showOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fotoğraf veya avatar
            _photos.isNotEmpty
                ? Image.network(_photos[0]['url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarBg())
                : _avatarBg(),

            // Alt gradient
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                  ),
                ),
              ),
            ),

            // Online badge
            Positioned(
              top: 56, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('Çevrimiçi',
                      style: TextStyle(fontSize: 11, color: kSuccess, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarBg() {
    return Container(
      color: kPrimaryLight,
      child: Center(
        child: Text(
          _name.isNotEmpty ? _name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w500, color: kPrimary),
        ),
      ),
    );
  }

  // ─── Temel bilgiler ──────────────────────────────────────────
  Widget _buildInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(width: 8),
          Text('$_age', style: const TextStyle(fontSize: 22, color: kTextSecondary)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 16, children: [
          _metaChip(Icons.location_on_outlined, _city),
          _metaChip(Icons.my_location_outlined,
              (() {
                final prefsList = _profile?['preferences'] as List?;
                if (prefsList == null || prefsList.isEmpty) return 'Arkadaşlık';
                return prefsList.first['purpose'] ?? 'Arkadaşlık';
              })()),
          _metaChip(Icons.access_time_outlined, _lastSeen()),
        ]),
        if (_bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(_bio, style: const TextStyle(fontSize: 14, color: kTextSecondary, height: 1.55)),
        ],
      ]),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: kTextSecondary),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
      ]),
    );
  }

  // ─── Fotoğraflar ─────────────────────────────────────────────
  Widget _buildPhotos() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FOTOĞRAFLAR',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: kTextSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemCount: _photos.length.clamp(0, 6),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(_photos[i]['url'], fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: kPrimaryLight,
                    child: const Icon(Icons.image_outlined, color: kPrimary))),
          ),
        ),
      ]),
    );
  }

  // ─── İlgi alanları ───────────────────────────────────────────
  Widget _buildInterests() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('İLGİ ALANLARI',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: kTextSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7, runSpacing: 7,
          children: _interests.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.3), width: 0.5),
            ),
            child: Text(tag, style: const TextStyle(
                fontSize: 13, color: kPrimaryDark, fontWeight: FontWeight.w500)),
          )).toList(),
        ),
      ]),
    );
  }

  // ─── Aksiyon butonları ────────────────────────────────────────
  Widget _buildActions() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _doSwipe('dislike'),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Geç'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextSecondary,
                side: const BorderSide(color: kBorder, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _doSwipe('like'),
              icon: const Icon(Icons.favorite_outline, size: 18),
              label: const Text('Beğen'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        TextButton.icon(
          onPressed: _showReportSheet,
          icon: const Icon(Icons.flag_outlined, size: 14, color: kTextSecondary),
          label: const Text('Şikayet et / Engelle',
              style: TextStyle(fontSize: 12, color: kTextSecondary)),
        ),
      ]),
    );
  }

  // ─── Swipe ────────────────────────────────────────────────────
  Future<void> _doSwipe(String action) async {
    try {
      await SupabaseService.swipe(widget.userId, action);
      if (mounted) Navigator.pop(context, action);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── Seçenekler menüsü ────────────────────────────────────────
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.block_outlined, color: Colors.orange),
            title: const Text('Engelle', style: TextStyle(fontSize: 15)),
            onTap: () { Navigator.pop(context); _blockUser(); },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.red),
            title: const Text('Şikayet et', style: TextStyle(fontSize: 15, color: Colors.red)),
            onTap: () { Navigator.pop(context); _showReportSheet(); },
          ),
        ]),
      ),
    );
  }

  // ─── Şikayet ─────────────────────────────────────────────────
  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReportSheet(userId: widget.userId),
    );
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Engelle'),
        content: Text('$_name kullanıcısını engellemek istiyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Engelle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      // TODO: Supabase'e block kaydı
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı engellendi'), backgroundColor: kSuccess));
      Navigator.pop(context);
    }
  }

  String _lastSeen() {
    final lastSeen = _profile?['last_seen'];
    if (lastSeen == null) return 'Aktif';
    final dt = DateTime.tryParse(lastSeen);
    if (dt == null) return 'Aktif';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 5) return 'Çevrimiçi';
    if (diff.inHours < 1)   return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24)  return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
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

// ─── Şikayet sayfası ──────────────────────────────────────────
class _ReportSheet extends StatefulWidget {
  final String userId;
  const _ReportSheet({required this.userId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selected;
  bool _sending = false;

  final _reasons = [
    'Uygunsuz fotoğraf veya içerik',
    'Sahte profil',
    'Taciz veya küfür',
    'Spam gönderim',
    'Küçük yaşta kullanıcı',
    'Diğer',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const Text('Şikayet sebebi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTextPrimary)),
          const SizedBox(height: 16),
          ..._reasons.map((r) => RadioListTile<String>(
            value: r,
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            title: Text(r, style: const TextStyle(fontSize: 14)),
            activeColor: kPrimary,
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: (_selected == null || _sending) ? null : _submit,
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Şikayet gönder'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _sending = true);
    try {
      await SupabaseService.reportUser(widget.userId, _selected!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şikayetin iletildi, teşekkürler'),
                backgroundColor: kSuccess));
      }
    } catch (_) {
      setState(() => _sending = false);
    }
  }
}
