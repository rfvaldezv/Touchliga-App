import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../models/dashboard_model.dart';
import 'quick_actions.dart';
import 'sections/competition_section.dart';
import 'sections/welcome_section.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key, required this.model});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        WelcomeSection(model: model.welcome),

        CompetitionSection(
          round: model.currentRound,
          pending: model.pendingPredictions,
        ),

        QuickActions(
          onPredictions: () {
            context.go(AppRouteNames.predictions);
          },

          onProfile: () {
            context.go(AppRouteNames.profile);
          },

          onDetalleJornada: () {
            context.push('${AppRouteNames.administration}/detalle-jornada');
          },

          onRanking: () {
            context.push('${AppRouteNames.administration}/ranking');
          },
        ),
      ],
    );
  }
}
