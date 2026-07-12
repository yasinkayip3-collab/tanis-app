import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'match_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String,dynamic>> _profiles = [];
  bool _loading = true;
  int _idx = 0;
  final _client = Supabase.instance.client;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _client.auth.currentUser?.id ?? '';
      final swipes = await _client.from('swipes').select('to_user').eq('from_user', uid);
      final ids = swipes.map((s) => s['to_user'].toString()).toList()..add(uid.isEmpty ? 'none' : uid);
      final res = await _client.from('users').select('*, photos(*), user_interests(*)').not('id','in','(${ids.join(',')})').eq('is_active',true).limit(20);
      setState(() { _profiles = List<Map<String,dynamic>>.from(res); _idx = 0; _loading = false; });
    } catch (e) {
      setState(() { _profiles = _mock; _idx = 0; _loading = false; });
    }
  }

  Future<void> _swipe(String action) async {
    if (_idx >= _profiles.length) return;
    final profile = _profiles[_idx];
    setState(() => _idx++);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      await _client.from('swipes').insert({'from_user': uid, 'to_user': profile['id'], 'action': action});
      if (action == 'like') await _checkMatch(profile);
    } catch (_) {}
  }

  Future<void> _checkMatch(Map<String,dynamic> profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final uid = _client.auth.currentUser!.id;
      final res = await _client.from('matches').select().or('user1_id.eq.$uid,user2_id.eq.$uid').order('matched_at').limit(1);
      if (res.isEmpty || !mounted) return;
      final match = res.first;
      final diff = DateTime.now().difference(DateTime.parse(match['matched_at'])).inSeconds;
      if (diff < 10) {
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => MatchScreen(matchId: match['id'], otherName: profile['name'] ?? '', myName: ''),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400)));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    appBar: AppBar(title: const Text('tanış'), actions: [IconButton(icon: const Icon(Icons.tune_outlined), onPressed: () {})]),
    body: _loading ? const Center(child: CircularProgressIndicator(color: kPrimary))
        : _idx >= _profiles.length ? _empty()
        : Column(children: [
            Expanded(child: _stack()),
            _buttons(),
            const SizedBox(height: 20),
          ]));

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.explore_off_outlined, size: 72, color: kBorder),
    const SizedBox(height: 16),
    const Text('Gösterilecek profil kalmadı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    const SizedBox(height: 24),
    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Yenile'),
      style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: const BorderSide(color: kPrimary))),
  ]));

  Widget _stack() {
    final rem = (_profiles.length - _idx).clamp(0, 3);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Stack(clipBehavior: Clip.none, children: [
      for (int i = rem-1; i > 0; i--)
        Positioned.fill(top: i*8.0, child: Transform.scale(scale: 1-i*0.03, child: _card(_profiles[_idx+i]))),
      if (rem > 0) _SwipeCard(key: ValueKey(_idx), profile: _profiles[_idx], onLeft: () => _swipe('dislike'), onRight: () => _swipe('like')),
    ]));
  }

  Widget _card(Map<String,dynamic> p) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder, width: 0.5)),
    child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Column(children: [
      Expanded(flex: 3, child: Container(color: kPrimaryLight, width: double.infinity,
        child: Center(child: Text(p['name']?[0] ?? '?', style: const TextStyle(fontSize: 72, color: kPrimary, fontWeight: FontWeight.w500))))),
      Expanded(flex: 2, child: Container(color: Colors.white)),
    ])));

  Widget _buttons() => Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    _btn(Icons.close, const Color(0xFFD85A30), 56, () => _swipe('dislike')),
    _btn(Icons.star_outline, const Color(0xFFBA7517), 48, () => _swipe('like')),
    _btn(Icons.favorite_outline, kSuccess, 64, () => _swipe('like')),
  ]));

  Widget _btn(IconData icon, Color color, double size, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: size, height: size,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0,4))]),
      child: Icon(icon, color: color, size: size*0.42)));

  final _mock = [
    {'id':'m1','name':'Ayşe','birthdate':'2000-05-12','city':'Samsun','bio':'Müzik seviyorum.','photos':[],'user_interests':[{'interest':'Müzik'},{'interest':'Seyahat'}]},
    {'id':'m2','name':'Merve','birthdate':'1998-09-23','city':'Ankara','bio':'Spor yapıyorum.','photos':[],'user_interests':[{'interest':'Spor'},{'interest':'Kitap'}]},
    {'id':'m3','name':'Zeynep','birthdate':'2002-03-07','city':'İstanbul','bio':'Sanata meraklıyım.','photos':[],'user_interests':[{'interest':'Sanat'},{'interest':'Dans'}]},
  ];
}

class _SwipeCard extends StatefulWidget {
  final Map<String,dynamic> profile;
  final VoidCallback onLeft, onRight;
  const _SwipeCard({super.key, required this.profile, required this.onLeft, required this.onRight});
  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Offset _off = Offset.zero;
  double _angle = 0;

  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300)); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onUpdate(DragUpdateDetails d) => setState(() { _off += d.delta; _angle = _off.dx/300*0.3; });
  void _onEnd(DragEndDetails _) {
    if (_off.dx > 100) { _out(const Offset(600,0)); Future.delayed(const Duration(milliseconds: 280), widget.onRight); }
    else if (_off.dx < -100) { _out(const Offset(-600,0)); Future.delayed(const Duration(milliseconds: 280), widget.onLeft); }
    else _reset();
  }

  void _out(Offset t) { final b=_off; final a=Tween<Offset>(begin:b,end:t).animate(CurvedAnimation(parent:_ctrl,curve:Curves.easeOut)); _ctrl.forward(from:0); a.addListener((){ setState((){_off=a.value;}); }); }
  void _reset() { final b=_off; final a=Tween<Offset>(begin:b,end:Offset.zero).animate(CurvedAnimation(parent:_ctrl,curve:Curves.elasticOut)); _ctrl.forward(from:0); a.addListener((){ setState((){_off=a.value;_angle=_off.dx/300*0.3;}); }); }

  int _age(String? b) { if(b==null)return 0; final d=DateTime.tryParse(b); if(d==null)return 0; final n=DateTime.now(); int a=n.year-d.year; if(n.month<d.month||(n.month==d.month&&n.day<d.day))a--; return a; }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final photos = p['photos'] as List? ?? [];
    final interests = (p['user_interests'] as List? ?? []).map((i)=>i['interest']?.toString()??'').where((s)=>s.isNotEmpty).take(3).toList();
    final name = p['name']?.toString() ?? '';
    final likeOp = (_off.dx/100).clamp(0.0,1.0);
    final nopeOp = (-_off.dx/100).clamp(0.0,1.0);

    return GestureDetector(onPanUpdate: _onUpdate, onPanEnd: _onEnd,
      child: Transform.translate(offset: _off, child: Transform.rotate(angle: _angle, child: Stack(children: [
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder, width: 0.5)),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: Container(width: double.infinity, color: kPrimaryLight,
              child: photos.isNotEmpty
                  ? Image.network(photos[0]['url']??'', fit: BoxFit.cover, errorBuilder: (_,__,___) => Center(child: Text(name.isNotEmpty?name[0]:'?', style: const TextStyle(fontSize: 72, color: kPrimary, fontWeight: FontWeight.w500))))
                  : Center(child: Text(name.isNotEmpty?name[0]:'?', style: const TextStyle(fontSize: 72, color: kPrimary, fontWeight: FontWeight.w500))))),
            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: kTextPrimary)),
                const SizedBox(width: 8),
                Text('${_age(p['birthdate']?.toString())}', style: const TextStyle(fontSize: 20, color: kTextSecondary)),
              ]),
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: kTextSecondary), const SizedBox(width: 3), Text(p['city']??'', style: const TextStyle(fontSize: 13, color: kTextSecondary))]),
              if ((p['bio']??'').isNotEmpty) ...[const SizedBox(height: 6), Text(p['bio'], style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)],
              const Spacer(),
              if (interests.isNotEmpty) Wrap(spacing: 6, runSpacing: 4, children: interests.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: kPrimary.withOpacity(0.3), width: 0.5)),
                child: Text(t, style: const TextStyle(fontSize: 11, color: kPrimaryDark, fontWeight: FontWeight.w500)))).toList()),
            ]))),
          ]))),
        if (likeOp > 0) Positioned(top: 28, right: 20, child: Opacity(opacity: likeOp, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kSuccess, width: 3)),
          child: const Text('BEĞEN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kSuccess))))),
        if (nopeOp > 0) Positioned(top: 28, left: 20, child: Opacity(opacity: nopeOp, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFFD85A30), width: 3)),
          child: const Text('PAS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFD85A30)))))),
      ]))));
  }
}
