import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import 'chat_screen.dart';

// ─── Eşleşme ekranı + konfeti ──────────────────────────────────
class MatchScreen extends StatefulWidget {
  final String matchId;
  final String otherName;
  final Map<String, dynamic> otherUser;
  final String myName;

  const MatchScreen({
    super.key,
    required this.matchId,
    required this.otherName,
    required this.otherUser,
    required this.myName,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  final List<_ConfettiParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // İçerik animasyonu
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _contentCtrl, curve: Curves.elasticOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _contentCtrl, curve: Curves.easeOutCubic));

    // Konfeti animasyonu
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..addListener(() => setState(() => _updateParticles()))
      ..forward();

    _spawnParticles();

    Future.delayed(const Duration(milliseconds: 200),
        () => _contentCtrl.forward());
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _spawnParticles() {
    for (int i = 0; i < 130; i++) {
      _particles.add(_ConfettiParticle(rng: _rng));
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.update();
    }
    _particles.removeWhere((p) => p.isDead);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Arka plan gradyan ────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7F77DD), Color(0xFF4A43A8)],
              ),
            ),
          ),

          // ── Konfeti canvas ───────────────────────────────────
          CustomPaint(
            painter: _ConfettiPainter(particles: _particles, size: size),
          ),

          // ── İçerik ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rozet
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.5),
                        ),
                        child: const Text(
                          '🎉  EŞLEŞMENİZ VAR!',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Başlık
                      const Text(
                        'Tebrikler!',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.otherName} ile eşleştin.\nHemen mesaj gönderin!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5),
                      ),
                      const SizedBox(height: 36),

                      // Avatarlar
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAvatar(widget.myName, size: 86),
                            const SizedBox(width: 12),
                            _PulsingHeart(),
                            const SizedBox(width: 12),
                            _buildAvatar(widget.otherName, size: 86),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),

                      // Mesaj gönder butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  matchId: widget.matchId,
                                  otherUser: widget.otherUser,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Mesaj Gönder',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Şimdi değil
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Şimdi Değil',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 3),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w500,
              color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Kalp animasyonu ───────────────────────────────────────────
class _PulsingHeart extends StatefulWidget {
  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: const Text('💜', style: TextStyle(fontSize: 32)),
    );
  }
}

// ─── Konfeti parçacığı ─────────────────────────────────────────
class _ConfettiParticle {
  final Random rng;
  late double x, y, speedX, speedY;
  late double size, rotation, rotSpeed;
  late Color color;
  late int shapeType; // 0=daire, 1=dikdörtgen, 2=kalp
  late double opacity;
  late double wobble, wobbleSpeed;
  bool isDead = false;

  static const _colors = [
    Color(0xFFFFFFFF),
    Color(0xFFA9A0EC),
    Color(0xFFF4C0D1),
    Color(0xFF5DCAA5),
    Color(0xFFFFD966),
    Color(0xFFFF8FA0),
    Color(0xFFBBEEDD),
  ];

  _ConfettiParticle({required this.rng}) {
    _init();
  }

  void _init() {
    x = rng.nextDouble();
    y = rng.nextDouble() * -0.3;
    speedX = (rng.nextDouble() - 0.5) * 0.008;
    speedY = 0.004 + rng.nextDouble() * 0.007;
    size = 6 + rng.nextDouble() * 10;
    rotation = rng.nextDouble() * pi * 2;
    rotSpeed = (rng.nextDouble() - 0.5) * 0.12;
    color = _colors[rng.nextInt(_colors.length)];
    shapeType = rng.nextInt(3);
    opacity = 1.0;
    wobble = rng.nextDouble() * pi * 2;
    wobbleSpeed = 0.05 + rng.nextDouble() * 0.08;
  }

  void update() {
    wobble += wobbleSpeed;
    x += speedX + sin(wobble) * 0.003;
    y += speedY;
    rotation += rotSpeed;
    if (y > 0.85) opacity = (1.0 - y) / 0.15;
    if (y > 1.05 || opacity <= 0) isDead = true;
  }
}

// ─── Konfeti painter ───────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Size size;

  _ConfettiPainter({required this.particles, required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0));

      final cx = p.x * sz.width;
      final cy = p.y * sz.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation);

      if (p.shapeType == 0) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else if (p.shapeType == 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * 0.45),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        _drawHeart(canvas, paint, p.size * 0.38);
      }

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, double s) {
    final path = Path()
      ..moveTo(0, s * 0.9)
      ..cubicTo(s * 2, -s * 0.5, s * 3.5, s * 1.5, 0, s * 3)
      ..cubicTo(-s * 3.5, s * 1.5, -s * 2, -s * 0.5, 0, s * 0.9)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
