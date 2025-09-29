import 'package:flutter/material.dart';
import '../home_screen.dart';
import 'step1_add_bank_screen.dart';
import 'step2_add_income_screen.dart';
import 'step3_add_budget_screen.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _finishOnboarding() {
     Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Your Financial Profile (Step ${_currentPage + 1} of 3)'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          AddBankScreen(onNext: _nextPage),
          AddIncomeScreen(onNext: _nextPage),
          AddBudgetScreen(onFinish: _finishOnboarding),
        ],
      ),
    );
  }
}

