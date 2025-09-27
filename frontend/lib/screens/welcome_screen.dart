import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_wrapper.dart';
import '../services/onboarding_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    final onboardingService = OnboardingService();
    onboardingService.setHasSeenWelcomeScreen().then((_) {
      // Navigate to the main app (which will show the LoginScreen)
      // and remove the welcome screen from the navigation stack.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // bg-slate-900
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: const [
              _WelcomeSlide(
                animation: _ChartAnimation(),
                title: "Muneem JI",
                text: "Helps you empower your financial future. Take control, one transaction at a time.",
                titleColor: Color(0xFF6EE7B7), // text-emerald-300
              ),
              _WelcomeSlide(
                animation: _ShieldAnimation(),
                title: "Muneem JI",
                text: "Respects your Privacy. We don't ask for any sensitive information. Your data is yours alone.",
                titleColor: Color(0xFF7DD3FC), // text-sky-300
              ),
               _WelcomeSlide(
                animation: _PenAnimation(),
                title: "Muneem JI",
                text: "Wants you to be honest. Diligently maintain your expenses for a clear financial picture.",
                titleColor: Color(0xFFFDE047), // text-amber-200
              ),
            ],
          ),
          // Navigation Dots
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
          // Register Button
          Positioned(
            bottom: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _onRegisterPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}

// Generic Slide Widget
class _WelcomeSlide extends StatelessWidget {
  final Widget animation;
  final String title;
  final String text;
  final Color titleColor;

  const _WelcomeSlide({
    required this.animation,
    required this.title,
    required this.text,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 192,
            width: 192,
            child: animation,
          ),
          Image.asset('assets/logo.png', height: 150),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Animations ---

class _ChartAnimation extends StatefulWidget {
  const _ChartAnimation();

  @override
  State<_ChartAnimation> createState() => __ChartAnimationState();
}

class __ChartAnimationState extends State<_ChartAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ChartBar(controller: _controller, heightFraction: 0.6, delay: 0.0),
        const SizedBox(width: 12),
        _ChartBar(controller: _controller, heightFraction: 0.8, delay: 0.2),
        const SizedBox(width: 12),
        _ChartBar(controller: _controller, heightFraction: 0.5, delay: 0.4),
        const SizedBox(width: 12),
        _ChartBar(controller: _controller, heightFraction: 0.9, delay: 0.6),
      ],
    );
  }
}

class _ChartBar extends AnimatedWidget {
  final double heightFraction;
  final double delay;

  const _ChartBar({
    required AnimationController controller,
    required this.heightFraction,
    required this.delay,
  }) : super(listenable: controller);

  Animation<double> get _scaleAnimation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final animationValue = CurveTween(curve: Interval(delay, 1.0, curve: Curves.easeInOut)).transform(_scaleAnimation.value);
    return FractionallySizedBox(
      heightFactor: heightFraction,
      child: Transform.scale(
        scaleY: animationValue,
        origin: const Offset(0, 100), // Not quite bottom, for effect
        child: Container(
          width: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF34D399), // bg-emerald-400
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldAnimation extends StatefulWidget {
  const _ShieldAnimation();
  @override
  State<_ShieldAnimation> createState() => _ShieldAnimationState();
}

class _ShieldAnimationState extends State<_ShieldAnimation> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _checkController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _checkController, curve: Curves.elasticOut));
    
    Future.delayed(const Duration(seconds: 1), () {
      if(mounted) _checkController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 160),
            ScaleTransition(
              scale: _checkAnimation,
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
          ],
        ),
      ),
    );
  }
}


class _PenAnimation extends StatefulWidget {
  const _PenAnimation();
  @override
  State<_PenAnimation> createState() => __PenAnimationState();
}
class __PenAnimationState extends State<_PenAnimation> with TickerProviderStateMixin {
  late AnimationController _penController;
  late AnimationController _line1Controller;
  late AnimationController _line2Controller;
  late AnimationController _line3Controller;

  @override
  void initState() {
    super.initState();
    _penController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: false);
    _line1Controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: false);
    _line2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: false);
    _line3Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: false);
  }

  @override
  void dispose() {
    _penController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _line3Controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 160,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFBBF24), style: BorderStyle.solid, width: 2),
              borderRadius: BorderRadius.circular(8)
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WritingLine(controller: _line1Controller, widthFactor: 1.0),
                _WritingLine(controller: _line2Controller, widthFactor: 0.8),
                _WritingLine(controller: _line3Controller, widthFactor: 0.9),
              ],
            )
          ),
           AnimatedBuilder(
            animation: _penController,
            builder: (context, child) {
              return Positioned(
                top: -8,
                left: 120 * _penController.value - 10,
                child: Transform.rotate(
                  angle: -0.785, // -45 degrees
                  child: const Icon(Icons.edit, color: Color(0xFFFDE047), size: 32))
              );
            },
          )
        ],
      ),
    );
  }
}
class _WritingLine extends StatefulWidget {
  final AnimationController controller;
  final double widthFactor;
  const _WritingLine({required this.controller, required this.widthFactor});

  @override
  State<_WritingLine> createState() => _WritingLineState();
}
class _WritingLineState extends State<_WritingLine> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: widget.controller.value * widget.widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 4,
            color: const Color(0xFFFBBF24),
          ),
        );
      },
    );
  }
}
