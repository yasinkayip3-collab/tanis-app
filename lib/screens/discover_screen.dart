import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/supabase_service.dart';
import 'match_screen.dart';
import 'user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    try {
      final profiles = await SupabaseService.getDiscoverProfiles();
      setState(() { _profiles = profiles; _loading = false; });
    } catch (_) {
      // Mock veri — Supabase bağlanana kadar
      setState(() { _profiles = _mockProfiles; _loading = false; });
    }
  }

  Future<void> _onSwipeRight() async {
    if (_currentIndex >= _profiles.length) return;
    final profile = _profiles[_currentIndex];
    setState(() => _currentIndex++);
    try {
      await SupabaseService.swipe(profile['id'], 'like');
      await _checkForMatch(profile);
    } catch (_) {}
  }

  Future<void> _onSwipeLeft() async {
    if (_currentIndex >= _profiles.length) return;
    final profile = _profiles[_currentIndex];
    setState(() => _currentIndex++);
    try {
      await SupabaseService.swipe(profile['id'], 'dislike');
    } catch (_) {}
  }

  Future<void> _checkForMatch(Map<String, dynamic> profile) async {
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final matches = await SupabaseService.getMatches();
      if (matches.isEmpty || !mounted) return;
      final latest = matches.first;
      final uid = SupabaseService.currentUser!.id;
      final isNew = DateTime.now()
          .difference(DateTime.parse(latest['matched_at']))
          .inSeconds < 5;
      if (!isNew) return;
      final myProfile = await SupabaseService.getProfile(uid);
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => MatchScreen(
            matchId: latest['id'],
            otherName: profile['name'] ?? '',
            otherUser: profile,
            myName: myProfile?['name'] ?? '',
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('tanış'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _currentIndex >= _profiles.length
              ? _buildEmpty()
              : Column(
                  children: [
                    Expanded(child: _buildCardStack()),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off_outlined, size: 72, color: kBorder),
          const SizedBox(height: 16),
          const Text('Gösterilecek profil kalmadı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kTextPrimary)),
          const SizedBox(height: 8),
          const Text('Daha sonra tekrar dene',
              style: TextStyle(color: kTextSecondary)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadProfiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
            style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    final remaining = (_profiles.length - _currentIndex).clamp(0, 3);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = remaining - 1; i > 0; i--)
            Positioned.fill(
              top: i * 8.0,
              child: Transform.scale(
                scale: 1 - i * 0.03,
                child: _buildStaticCard(_profiles[_currentIndex + i]),
              ),
            ),
          if (remaining > 0)
            _SwipeCard(
              key: ValueKey(_currentIndex),
              profile: _profiles[_currentIndex],
              onSwipeLeft: _onSwipeLeft,
              onSwipeRight: _onSwipeRight,
            ),
        ],
      ),
    );
  }

  Widget _buildStaticCard(Map<String, dynamic> profile) {
    final name = profile['name'] ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: kPrimaryLight,
                width: double.infinity,
                child: Center(
                  child: Text(name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(fontSize: 72, color: kPrimary, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            Expanded(flex: 2, child: Container(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleButton(icon: Icons.close, color: const Color(0xFFD85A30), size: 56, onTap: _onSwipeLeft),
          _CircleButton(icon: Icons.star_outline, color: const Color(0xFFBA7517), size: 48, onTap: _onSwipeRight),
          _CircleButton(icon: Icons.favorite_outline, color: kSuccess, size: 64, onTap: _onSwipeRight),
        ],
      ),
    );
  }
}

// ─── Sürüklenebilir kart ───────────────────────────────────────
class _SwipeCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const _SwipeCard({super.key, required this.profile, required this.onSwipeLeft, required this.onSwipeRight});

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Offset _offset = Offset.zero;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _offset += d.delta;
      _angle = _offset.dx / 300 * 0.3;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_offset.dx > 100) {
      _animateOut(const Offset(600, 0));
      Future.delayed(const Duration(milliseconds: 280), widget.onSwipeRight);
    } else if (_offset.dx < -100) {
      _animateOut(const Offset(-600, 0));
      Future.delayed(const Duration(milliseconds: 280), widget.onSwipeLeft);
    } else {
      _resetCard();
    }
  }

  void _animateOut(Offset target) {
    final begin = _offset;
    final anim = Tween<Offset>(begin: begin, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0);
    anim.addListener(() => setState(() => _offset = anim.value));
  }

  void _resetCard() {
    final begin = _offset;
    final anim = Tween<Offset>(begin: begin, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward(from: 0);
    anim.addListener(() => setState(() {
      _offset = anim.value;
      _angle = _offset.dx / 300 * 0.3;
    }));
  }

  double get _likeOpacity => (_offset.dx / 100).clamp(0.0, 1.0);
  double get _nopeOpacity => (-_offset.dx / 100).clamp(0.0, 1.0);

  int _calcAge(String? b) {
    if (b == null) return 0;
    final dt = DateTime.tryParse(b);
    if (dt == null) return 0;
    final now = DateTime.now();
    int age = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) age--;
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final photos = profile['photos'] as List? ?? [];
    final interests = (profile['user_interests'] as List? ?? [])
        .map<String>((i) => i is String ? i : ((i as Map)['interest']?.toString() ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
    final name = profile['name'] ?? '';

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: _angle,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          color: kPrimaryLight,
                          child: photos.isNotEmpty
                              ? Image.network(photos[0]['url'], fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(name.isNotEmpty ? name[0] : '?',
                                        style: const TextStyle(fontSize: 72, color: kPrimary, fontWeight: FontWeight.w500))))
                              : Center(child: Text(name.isNotEmpty ? name[0] : '?',
                                  style: const TextStyle(fontSize: 72, color: kPrimary, fontWeight: FontWeight.w500))),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: kTextPrimary)),
                              const SizedBox(width: 8),
                              Text(_calcAge(profile['birthdate']).toString(),
                                  style: const TextStyle(fontSize: 20, color: kTextSecondary)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: kTextSecondary),
                              const SizedBox(width: 3),
                              Text(profile['city'] ?? '', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                            ]),
                            if ((profile['bio'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(profile['bio'], style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.4),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            const Spacer(),
                            if (interests.isNotEmpty)
                              Wrap(spacing: 6, runSpacing: 4,
                                children: interests.take(3).map<Widget>((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: kPrimaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: kPrimary.withOpacity(0.3), width: 0.5)),
                                  child: Text(tag is String ? tag : tag['interest'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: kPrimaryDark, fontWeight: FontWeight.w500)),
                                )).toList()),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_likeOpacity > 0)
                Positioned(top: 28, right: 20,
                  child: Opacity(opacity: _likeOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kSuccess, width: 3)),
                      child: const Text('BEĞEN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kSuccess)),
                    ))),
              if (_nopeOpacity > 0)
                Positioned(top: 28, left: 20,
                  child: Opacity(opacity: _nopeOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD85A30), width: 3)),
                      child: const Text('PAS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFD85A30))),
                    ))),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.color, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: kBorder, width: 0.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}

final _mockProfiles = [
  {'id': 'mock-1', 'name': 'Ayşe', 'birthdate': '2000-05-12', 'city': 'Samsun',
    'bio': 'Müzik dinlemekten ve yeni yerler keşfetmekten hoşlanıyorum.',
    'photos': [], 'interests': ['Müzik', 'Seyahat', 'Sinema']},
  {'id': 'mock-2', 'name': 'Merve', 'birthdate': '1998-09-23', 'city': 'Ankara',
    'bio': 'Spor yapıyorum, kitap okuyorum.',
    'photos': [], 'interests': ['Spor', 'Kitap', 'Yemek']},
  {'id': 'mock-3', 'name': 'Zeynep', 'birthdate': '2002-03-07', 'city': 'İstanbul',
    'bio': 'Sanat ve tasarımla ilgileniyorum.',
    'photos': [], 'interests': ['Sanat', 'Teknoloji', 'Dans']},
  {'id': 'mock-4', 'name': 'Elif', 'birthdate': '1996-11-18', 'city': 'İzmir',
    'bio': 'Fotoğrafçılık ve doğa yürüyüşleri en büyük hobim.',
    'photos': [], 'interests': ['Fotoğraf', 'Doğa', 'Bisiklet']},
];
