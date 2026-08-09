import 'package:flutter/material.dart';

import '../models/welcome_model.dart';
import '../../../shared/design_system/widgets/cards/app_card.dart';
import '../../../shared/design_system/tokens/app_colors.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.model});

  final WelcomeModel model;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Bienvenido',
      icon: Icons.waving_hand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.userName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(model.leagueName, style: const TextStyle(fontSize: 16)),

          Text(
            model.tournamentName,
            style: const TextStyle(color: Colors.grey),
          ),

          const Divider(height: 32),

          Row(
            children: [
              Expanded(
                child: _Statistic(
                  title: 'Posición',
                  value: '${model.position}°',
                  color: AppColors.primary,
                ),
              ),

              Expanded(
                child: _Statistic(
                  title: 'Puntos',
                  value: '${model.points}',
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Statistic extends StatelessWidget {
  const _Statistic({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }
}
