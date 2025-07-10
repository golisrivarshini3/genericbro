import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'generic_medicine_finder.dart';
import 'pharmacy_locator.dart';
import '../utils/theme.dart';
import '../widgets/animated_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Widget _buildGlowEffect({
    required Alignment alignment,
    required double width,
    required double height,
  }) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            _backgroundAnimation.value * MediaQuery.of(context).size.height,
          ),
          child: Container(
            width: width,
            height: height,
              decoration: BoxDecoration(
              gradient: RadialGradient(
                center: alignment,
                radius: 1.0,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: AppTheme.gradientBackground,
          ),

          // Animated glow effects
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.2,
            child: _buildGlowEffect(
              alignment: Alignment.topRight,
              width: size.width * 0.8,
              height: size.height * 0.8,
              ),
            ),
          Positioned(
            bottom: -size.height * 0.3,
            left: -size.width * 0.3,
            child: _buildGlowEffect(
              alignment: Alignment.bottomLeft,
              width: size.width * 0.8,
              height: size.height * 0.8,
            ),
          ),

          // Main content
          SafeArea(
            child: isLandscape
                ? Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildLogo(),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildButtons(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildLogo(),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                      _buildButtons(),
                      const Spacer(),
                    ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding * 2),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        tween: Tween<double>(begin: 0.5, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Hero(
          tag: 'app_logo',
          child: Image.asset(
            'assets/images/Swecha_Logo_English.png',
            color: Colors.white,
            height: MediaQuery.of(context).size.height * 0.2,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.defaultPadding,
      ),
            child: Column(
        mainAxisSize: MainAxisSize.min,
              children: [
          AnimatedButton(
            text: 'Find Generic Medicines',
                  icon: Icons.medication,
            index: 0,
            onPressed: () {
              Navigator.push(
                    context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const GenericMedicineFinder(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          AnimatedButton(
                  text: 'Pharmacy Locator',
                  icon: Icons.location_on,
            index: 1,
            onPressed: () {
              Navigator.push(
                    context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const PharmacyLocator(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          AnimatedButton(
            text: 'Prescription Reader',
            icon: Icons.document_scanner,
            index: 2,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Prescription Reader coming soon!',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
                  ),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(AppTheme.defaultPadding),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 