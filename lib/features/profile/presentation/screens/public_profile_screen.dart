import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../providers/profile_controller.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final userId = args is Map ? (args['userId'] ?? '').toString() : '';

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Missing user id for public profile')),
      );
    }

    final profileAsync = ref.watch(publicProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Player Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (profile) {
          final matchesPlayed = profile.matchesPlayed;
          final won = profile.matchesWon;
          final winRate = matchesPlayed == 0 ? 0 : (won / matchesPlayed) * 100;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage: profile.profileImageUrl.isEmpty
                    ? null
                    : NetworkImage(profile.profileImageUrl),
                child: profile.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 42)
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text('Skill: ${profile.skillLevel.toUpperCase()}'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ELO: ${profile.eloRating}'),
                      const SizedBox(height: 6),
                      Text('Reliability: ${profile.reliabilityScore}'),
                      if (profile.showMatchHistory) ...[
                        const SizedBox(height: 6),
                        Text('Matches: $matchesPlayed'),
                        const SizedBox(height: 6),
                        Text('Win rate: ${winRate.round()}%'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.preferredRoles
                        .map((role) => Chip(label: Text(role)))
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
