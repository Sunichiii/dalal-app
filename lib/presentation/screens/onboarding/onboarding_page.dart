import 'package:flutter/material.dart';
import 'package:groupie_v2/presentation/screens/onboarding/second_onboard.dart';
import '../../../core/shared/constants.dart';
import '../../../core/shared/textstyles.dart';
import '../../../data/sources/helper_function.dart';
import '../../../logic/auth/login/login_page.dart';
import 'first_onboard.dart';
class OnboardingPage extends StatefulWidget {
  final VoidCallback? onCompleted;
  const OnboardingPage({super.key, this.onCompleted});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().backGroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => currentPage = index),
                children: const [
                  FirstOnboardScreen(),
                  SecondOnboardScreen(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: ElevatedButton(
                onPressed: () async {
                  if (currentPage == 0) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // Mark onboarding as completed
                    await HelperFunctions.setOnboardingCompleted();

                    // Navigate to login or home based on auth status
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants().primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(200, 50),
                ),
                child: Text(
                  currentPage == 0 ? "Next" : "Get Started",
                  style: AppTextStyles.small,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}