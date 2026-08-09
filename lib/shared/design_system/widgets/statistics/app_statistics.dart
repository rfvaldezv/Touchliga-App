import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class AppStatistic extends StatelessWidget {
  const AppStatistic({super.key, required this.title, required this.value});

  final String title;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge),

        Text(title, style: AppTextStyles.caption),
      ],
    );
  }
}
