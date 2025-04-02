import 'package:flutter/material.dart';
import 'package:groupie_v2/core/shared/constants.dart';
import 'package:groupie_v2/core/shared/textstyles.dart';

class SecondOnboardScreen extends StatelessWidget {
  const SecondOnboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/group.png',
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            "Connect, Share, Explore",
            style: AppTextStyles.medium,
          ),
        ],
      ),
    );
  }
}
