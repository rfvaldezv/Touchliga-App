import 'package:flutter/material.dart';

import '../../models/welcome_model.dart';
import '../welcome_card.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key, required this.model});

  final WelcomeModel model;

  @override
  Widget build(BuildContext context) {
    return WelcomeCard(model: model);
  }
}
