import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    this.onPredictions,
    this.onProfile,
    this.onDetalleJornada,
    this.onRanking,
  });

  final VoidCallback? onPredictions;
  final VoidCallback? onProfile;
  final VoidCallback? onDetalleJornada;
  final VoidCallback? onRanking;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.sports_soccer,
        label: 'Pronósticos',
        onTap: onPredictions,
      ),
      _QuickActionItem(icon: Icons.person, label: 'Perfil', onTap: onProfile),
      _QuickActionItem(
        icon: Icons.grid_on_outlined,
        label: 'Detalle por jornada',
        onTap: onDetalleJornada,
      ),
      _QuickActionItem(
        icon: Icons.leaderboard_outlined,
        label: 'Ranking',
        onTap: onRanking,
      ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accesos rápidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (_, index) {
                final action = actions[index];

                return _ActionButton(
                  icon: action.icon,
                  label: action.label,
                  onTap: action.onTap,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
