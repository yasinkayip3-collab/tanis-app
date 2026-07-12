import 'package:flutter/material.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
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
          // Fotoğraf - hata olursa mor arka plan göster
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.62,
            child: Image.asset(
              'assets/splash_heart.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: kPrimaryLight,
                child: const Center(
                  child: Icon(Icons.favorite, size: 80, color: kPrimary),
                ),
              ),
            ),
          ),

          // Beyaz geçiş
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.52,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white, Colors.white],
                  stops: [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),

          // İçerik
          Positioned(
            bottom: 0, left: 0, right: 0,
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
                      const Text('tanış',
                          style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: -1.5,
                              height: 1)),
                      const SizedBox(height: 10),
                      const Text(
                        'Yeni insanlarla tanış,\ngerçek bağlantılar kur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, color: kTextSecondary, height: 1.55),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Başla',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text('18 yaşından büyük olman gerekiyor',
                          style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondary.withOpacity(0.65))),
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
