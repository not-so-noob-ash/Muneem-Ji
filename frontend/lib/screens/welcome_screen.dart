import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';
import 'auth_wrapper.dart';

// Main Welcome Screen Widget
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSlideShow();
  }

  void _startSlideShow() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      int nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        nextPage,
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

  void _onFinish() {
    ref.read(onboardingServiceProvider).setWelcomeScreenSeen();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
              _EmpowerSlide(),
              _PrivacySlide(),
              _HonestySlide(),
            ],
          ),
          // Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _onFinish,
              child: const Text('Skip'),
            ),
          ),
          // Dots and Get Started Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: _currentPage == 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    onPressed: _onFinish,
                    child: const Text('Get Started'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Slide 1: Empower (Growing Chart Animation) ---
class _EmpowerSlide extends StatefulWidget {
  const _EmpowerSlide();

  @override
  State<_EmpowerSlide> createState() => _EmpowerSlideState();
}

class _EmpowerSlideState extends State<_EmpowerSlide> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    return _SlideBase(
      title: "Empower Your Finances",
      subtitle: "Take control of your financial future, one transaction at a time.",
      accentColor: Colors.tealAccent[400]!,
      animationArea: SizedBox(
        height: 150,
        width: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ChartBar(controller: _controller, heightFraction: 0.6, delay: 0.0),
            _ChartBar(controller: _controller, heightFraction: 0.8, delay: 0.2),
            _ChartBar(controller: _controller, heightFraction: 0.5, delay: 0.4),
            _ChartBar(controller: _controller, heightFraction: 0.9, delay: 0.6),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final delayedAnimation = CurvedAnimation(parent: animation, curve: Interval(delay, 1.0, curve: Curves.easeInOut));
    return Container(
      width: 20,
      height: 150 * heightFraction * delayedAnimation.value,
      decoration: BoxDecoration(
        color: Colors.tealAccent[400],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
    );
  }
}

// --- Slide 2: Privacy (Pulsing Shield Animation) ---
class _PrivacySlide extends StatefulWidget {
  const _PrivacySlide();
  @override
  State<_PrivacySlide> createState() => __PrivacySlideState();
}

class __PrivacySlideState extends State<_PrivacySlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      title: "Your Privacy Matters",
      subtitle: "We don't ask for sensitive information. Your data is yours alone.",
      accentColor: Colors.lightBlueAccent[200]!,
      animationArea: SizedBox(
        height: 150,
        width: 150,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: Icon(Icons.shield_outlined, color: Colors.lightBlueAccent[200]!, size: 140),
        ),
      ),
    );
  }
}


// --- Slide 3: Honesty (Writing Animation) ---
class _HonestySlide extends StatefulWidget {
  const _HonestySlide();
  @override
  State<_HonestySlide> createState() => __HonestySlideState();
}

class __HonestySlideState extends State<_HonestySlide> with SingleTickerProviderStateMixin {
   late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      title: "Be Honest With Yourself",
      subtitle: "Diligently maintain your expenses for a clear financial picture.",
      accentColor: Colors.amberAccent[200]!,
      animationArea: SizedBox(
        height: 150,
        width: 150,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WritingPainter(_controller.value, Colors.amberAccent[200]!),
            );
          },
        ),
      ),
    );
  }
}

class _WritingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _WritingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Simulate drawing a simple graph line
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width * 0.9, size.height * 0.3);

    final totalLength = path.computeMetrics().first.length;
    final currentLength = totalLength * progress;

    final BoundingBox = path.getBounds();
    
    final clippedPath = path.computeMetrics().first.extractPath(0, currentLength);
    canvas.drawPath(clippedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// --- Base Widget for all slides to avoid code duplication ---
class _SlideBase extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget animationArea;

  const _SlideBase({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.animationArea,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          animationArea,
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

