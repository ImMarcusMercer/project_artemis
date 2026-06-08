import 'package:flutter/material.dart';

import '../../bootstrap/backend_bootstrap.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/resq_widgets.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.backendState, required this.onGetStarted});

  final BackendState backendState;
  final VoidCallback onGetStarted;

  static const features = [
    ('⚡', 'AI Symptom Triage'),
    ('🆘', 'One-tap SOS Dispatch'),
    ('🧠', 'Mental Health Hub'),
    ('📡', 'LoRaWAN Compact Mode'),
    ('📊', 'Real-time Monitoring'),
    ('🗺️', 'Live Risk Map'),
  ];

  static const stats = [
    ('4,821', 'Registered Users'),
    ('156', 'Barangays Covered'),
    ('8.4m', 'Avg Response Time'),
    ('24/7', 'Always On'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Text('⚕️', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    const Text('ResQ', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    TextButton(
                      onPressed: onGetStarted,
                      child: const Text('Sign In →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.yellow.withOpacity(.35)),
                        ),
                        child: const Text(
                          '🇵🇭 Philippines Health & Emergency Platform',
                          style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'ResQ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 72, height: 1, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Bridging the healthcare and emergency response gap —',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 21, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: const Text(
                          'From urban centers to remote barangays across the Philippines. Rapid SOS dispatch, AI-assisted triage, mental wellness, and monitoring in one platform.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.65),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: PrimaryButton(label: 'Get Started', icon: Icons.arrow_forward_rounded, onPressed: onGetStarted),
                      ),
                      const SizedBox(height: 34),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _RoleChip(emoji: '👤', label: 'Citizen', color: AppColors.yellow),
                          _RoleChip(emoji: '🚑', label: 'Responder', color: AppColors.red),
                          _RoleChip(emoji: '👩‍⚕️', label: 'Professional', color: AppColors.teal),
                          _RoleChip(emoji: '🏛️', label: 'Admin', color: AppColors.purple),
                        ],
                      ),
                      const SizedBox(height: 34),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth > 720 ? 4 : 2;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.15,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: stats
                                .map((item) => Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.07),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(.08)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(item.$1, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 4),
                                          Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: features
                              .map((feature) => Container(
                                    width: 245,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.075),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(feature.$1, style: const TextStyle(fontSize: 21)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(feature.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('© 2026 ResQ · Artemis v1.1', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.emoji, required this.label, required this.color});

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
