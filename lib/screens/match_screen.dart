import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'chat_screen.dart';

class MatchScreen extends StatefulWidget {
  final String matchId, otherName, myName;
  final Map<String,dynamic>? otherUser;
  const MatchScreen({super.key, required this.matchId, required this.otherName, required this.myName, this.otherUser});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late AnimationController _confCtrl, _contentCtrl;
  late Animation<double> _fadeAnim, _scaleAnim;
  late Animation<Offset> _slideAnim;
  final List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _confCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addListener(() => setState(() => _particles.removeWhere((p) { p.update(); return p.dead; })))
      ..forward();
    _fadeAnim  = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.elasticOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    for (int i = 0; i < 120; i++) _particles.add(_Particle(_rng));
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _contentCtrl.forward(); });
  }

  @override
  void dispose() { _confCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(body: Stack(fit: StackFit.expand, children: [
      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7F77DD), Color(0xFF4A43A8)]))),
      CustomPaint(painter: _ConfettiPainter(_particles, size)),
      SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5)),
          child: const Text('🎉  EŞLEŞMENİZ VAR!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1))),
        const SizedBox(height: 20),
        const Text('Tebrikler!', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('${widget.otherName} ile eşleştin.\nHemen mesaj gönderin!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.5)),
        const SizedBox(height: 32),
        ScaleTransition(scale: _scaleAnim, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _av(widget.myName),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: _PulseHeart()),
          _av(widget.otherName),
        ])),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: widget.matchId, otherUser: widget.otherUser ?? {'name': widget.otherName}))),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Mesaj Gönder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 50, child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Şimdi Değil'))),
      ]))))),
    ]));
  }

  Widget _av(String name) => Container(width: 80, height: 80,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.7), width: 3)),
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: Colors.white))));
}

class _PulseHeart extends StatefulWidget {
  const _PulseHeart();
  @override
  State<_PulseHeart> createState() => _PulseHeartState();
}
class _PulseHeartState extends State<_PulseHeart> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _a = Tween<double>(begin:1.0,end:1.3).animate(CurvedAnimation(parent:_c,curve:Curves.easeInOut)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _a, child: const Text('💜', style: TextStyle(fontSize: 32)));
}

class _Particle {
  final Random rng;
  late double x,y,sx,sy,size,rot,rotS,opacity,wobble,wobbleS;
  late Color color;
  late int shape;
  bool dead = false;
  static const _colors = [Color(0xFFFFFFFF),Color(0xFFA9A0EC),Color(0xFFF4C0D1),Color(0xFF5DCAA5),Color(0xFFFFD966),Color(0xFFFF8FA0)];
  _Particle(this.rng) { x=rng.nextDouble(); y=rng.nextDouble()*-0.3; sx=(rng.nextDouble()-0.5)*0.008; sy=0.004+rng.nextDouble()*0.007; size=6+rng.nextDouble()*10; rot=rng.nextDouble()*pi*2; rotS=(rng.nextDouble()-0.5)*0.12; color=_colors[rng.nextInt(_colors.length)]; shape=rng.nextInt(3); opacity=1.0; wobble=rng.nextDouble()*pi*2; wobbleS=0.05+rng.nextDouble()*0.08; }
  void update() { wobble+=wobbleS; x+=sx+sin(wobble)*0.003; y+=sy; rot+=rotS; if(y>0.85)opacity=(1.0-y)/0.15; if(y>1.05||opacity<=0)dead=true; }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final Size size;
  _ConfettiPainter(this.particles, this.size);
  @override
  void paint(Canvas canvas, Size sz) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0,1.0));
      canvas.save(); canvas.translate(p.x*sz.width, p.y*sz.height); canvas.rotate(p.rot);
      if (p.shape==0) { canvas.drawCircle(Offset.zero, p.size/2, paint); }
      else if (p.shape==1) { canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset.zero,width:p.size,height:p.size*0.45),const Radius.circular(2)), paint); }
      else { final path=Path()..moveTo(0,p.size*0.33)..cubicTo(p.size*0.74,-p.size*0.18,p.size*1.3,p.size*0.56,0,p.size*1.1)..cubicTo(-p.size*1.3,p.size*0.56,-p.size*0.74,-p.size*0.18,0,p.size*0.33)..close(); canvas.drawPath(path, paint); }
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_ConfettiPainter _) => true;
}
