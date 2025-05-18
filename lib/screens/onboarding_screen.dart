import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../screens/nearby_chats_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Sifter',
      description: 'Connect with people nearby through hyperlocal chat rooms',
      imageAsset: 'assets/images/onboarding_welcome.json',
    ),
    OnboardingPage(
      title: 'Location-Based Chats',
      description: 'Chat rooms only appear when you\'re physically in range (up to 200 meters)',
      imageAsset: 'assets/images/onboarding_location.json',
    ),
    OnboardingPage(
      title: 'Stay Within Range',
      description: 'You can only send messages when you\'re physically present in the chat area',
      imageAsset: 'assets/images/onboarding_range.json',
    ),
    OnboardingPage(
      title: 'Create Your Own Chats',
      description: 'Start conversations at your location and choose how far they should reach',
      imageAsset: 'assets/images/onboarding_create.json',
    ),
    OnboardingPage(
      title: 'Ready to Explore',
      description: 'Discover chats near you and join the conversation!',
      imageAsset: 'assets/images/onboarding_explore.json',
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Navigate to the nearby chats screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NearbyChatsScreen()),
      );
    }
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _isLastPage = index == _pages.length - 1;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildOnboardingPage(page);
            },
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Skip button (except on last page)
            if (!_isLastPage)
              TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              )
            else
              const SizedBox.shrink(),
              
            // Page indicator
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
            
            // Next/Get Started button
            _isLastPage
                ? ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Get Started'),
                  )
                : ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration
          Expanded(
            flex: 2,
            child: Lottie.asset(
              page.imageAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imageAsset;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.imageAsset,
  });
} 