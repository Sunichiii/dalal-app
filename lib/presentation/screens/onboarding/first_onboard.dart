import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/shared/textstyles.dart';
class FirstOnboardScreen extends StatelessWidget {
  const FirstOnboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Back animation with slight offset
            Positioned(
              left: 20,
              bottom: 20,
              child: Opacity(
                opacity: 0.5,
                child: Lottie.asset(
                  'assets/lottie/Animation - 1743584033129.json',
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Main animation
            Lottie.asset(
              'assets/lottie/Animation - 1743584033129.json',
              height: 250,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          "WHERE GROUPS\nBECOME CONVERSATIONS",
          textAlign: TextAlign.center,
          style: AppTextStyles.medium,
        ),
        // Add space where the button will be placed
        const SizedBox(height: 40), // Adjust this value as needed
      ],
    );
  }
}