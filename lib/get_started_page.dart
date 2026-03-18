import 'package:flutter/material.dart';
import 'welcome_page.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with TickerProviderStateMixin {
  late AnimationController _bagController;
  late AnimationController _shadowController;
  late AnimationController _leaf1Controller;
  late AnimationController _leaf2Controller;
  late AnimationController _leaf3Controller;

  late Animation<Offset> _bagAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<Offset> _leaf1Animation;
  late Animation<Offset> _leaf2Animation;
  late Animation<Offset> _leaf3Animation;

  @override
  void initState() {
    super.initState();

    // Bag rise animation
    _bagController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bagAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bagController, curve: Curves.easeOut));

    // Shadow fade animation
    _shadowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shadowController, curve: Curves.easeIn));

    // Leaf 1 pan from left
    _leaf1Controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _leaf1Animation = Tween<Offset>(
      begin: const Offset(-2.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _leaf1Controller, curve: Curves.easeOut));

    // Leaf 2 pan from right
    _leaf2Controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _leaf2Animation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _leaf2Controller, curve: Curves.easeOut));

    // Leaf 3 pan from right
    _leaf3Controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _leaf3Animation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _leaf3Controller, curve: Curves.easeOut));

    // Start animations
    _shadowController.forward();
    _bagController.forward();
    _leaf1Controller.forward();
    _leaf2Controller.forward();
    _leaf3Controller.forward();
  }

  @override
  void dispose() {
    _bagController.dispose();
    _shadowController.dispose();
    _leaf1Controller.dispose();
    _leaf2Controller.dispose();
    _leaf3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow at top with fade animation - fill
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _shadowAnimation,
              child: Image.asset(
                'images/shadow.png',
                width: double.infinity,
                height: 444,
                fit: BoxFit.fill,
              ),
            ),
          ),

          // Veggie at bottom with rise animation - behind everything
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _bagAnimation,
              child: Image.asset(
                'images/veggie.png',
                width: double.infinity,
                height: 360,
                fit: BoxFit.fill,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          // Leaf 1 - pan from left, positioned at top
          Positioned(
            top: 50,
            left: 20,
            child: SlideTransition(
              position: _leaf1Animation,
              child: Image.asset(
                'images/leaf.png',
                width: 34,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Leaf 2 - pan from right
          Positioned(
            top: 100,
            right: 30,
            child: SlideTransition(
              position: _leaf2Animation,
              child: Image.asset(
                'images/leaf (2).png',
                width: 46,
                height: 39,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Leaf 3 - pan from right - full image, no clipping
          Positioned(
            top: 200,
            right: 20,
            child: SlideTransition(
              position: _leaf3Animation,
              child: Image.asset(
                'images/bleaf.png',
                width: 46,
                height: 39,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // Main content - in front of bag
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Get your groceries delivered to your home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sub heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'The best delivery app in town for delivering your daily fresh groceries',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Logo centered
                Image.asset(
                  'images/logo.png',
                  width: 212,
                  height: 110,
                  fit: BoxFit.contain,
                ),

                const Spacer(flex: 2),

                // Shop Now Button - in front
                Center(
                  child: SizedBox(
                    width: 190,
                    height: 53,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        minimumSize: const Size(190, 53),
                        maximumSize: const Size(190, 53),
                        fixedSize: const Size(190, 53),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            26.5,
                          ), // More circular corners (half of height)
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Shop Now',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
