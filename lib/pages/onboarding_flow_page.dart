import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_billetera_digital/pages/auth_gate_page.dart'; // Navigate to AuthGatePage after onboarding

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Store data, not widgets, for better performance and dynamic theme handling
  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Bienvenido a Mi Billetera Digital',
      'description': 'Tu asistente personal para gestionar tus finanzas.',
      'imagePath': 'logo', // Special key to use the theme-aware app logo
    },
    {
      'title': 'Controla tus Gastos',
      'description': 'Registra tus ingresos y egresos fácilmente.',
      'imagePath':
          'assets/images/google_logo.png', // Specific image for this page
    },
    {
      'title': 'Alcanza tus Metas',
      'description': 'Crea metas de ahorro y sigue tu progreso.',
      'imagePath': 'logo', // Special key to use the theme-aware app logo
    },
  ];

  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 200),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onSkipPressed() {
    _completeOnboarding();
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGatePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAssetPath =
        isDarkMode ? 'assets/images/oscuro.png' : 'assets/images/logo.png';

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final pageData = _onboardingData[index];
              String imagePath = pageData['imagePath']!;
              // Use the theme-aware logo if the imagePath is our special key
              if (imagePath == 'logo') {
                imagePath = logoAssetPath;
              }
              return _buildOnboardingPage(
                title: pageData['title']!,
                description: pageData['description']!,
                imagePath: imagePath,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkipPressed,
                    child: const Text('Saltar'),
                  ),
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: _currentPage == index ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _onNextPressed,
                    child: Text(_currentPage == _onboardingData.length - 1
                        ? 'Empezar'
                        : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
