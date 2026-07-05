import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 150), () {
      _fadeCtrl.forward();
      _slideCtrl.forward();
      _progressCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fotoğraf ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.62,
            child: Image.asset(
              'assets/splash_heart.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Beyaz geçiş ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),

          // ── İçerik ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.46,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      const Text(
                        'tanış',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Slogan
                      const Text(
                        'Yeni insanlarla tanış,\ngerçek bağlantılar kur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: kTextSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Başla butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            // AppRouter auth durumuna göre otomatik yönlendirir
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Başla',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // İlerleme çubuğu
                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 2,
                              width: double.infinity,
                              child: LinearProgressIndicator(
                                value: _progressCtrl.value,
                                backgroundColor: kPrimaryLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    kPrimary),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),

                      // Alt not
                      Text(
                        '18 yaşından büyük olman gerekiyor',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary.withOpacity(0.65),
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
}
