import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.user, required this.firestoreService, required this.mode});

  final AppUser user;
  final FirestoreService firestoreService;
  final String mode;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case 'hotspots':
        return _HotspotsAdmin(firestoreService: firestoreService);
      case 'users':
        return _UsersAdmin(user: user, firestoreService: firestoreService);
      case 'reports':
        return const _ReportsAdmin();
      default:
        return _OverviewAdmin(user: user, firestoreService: firestoreService);
    }
  }
}

class _OverviewAdmin extends StatelessWidget {
  const _OverviewAdmin({required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Admin Overview',
          subtitle: 'LGU-level operational dashboard for users, incidents, appointments, and health hotspots.',
          trailing: PrimaryButton(
            label: 'Seed Demo Data',
            icon: Icons.dataset_rounded,
            fullWidth: false,
            color: AppColors.purple,
            onPressed: () async {
              await firestoreService.seedDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(firestoreService.ready ? 'Demo collections seeded.' : 'Mock mode: seeding skipped.')));
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        const ResponsiveGrid(
          children: [
            StatCard(value: '4,821', label: 'Registered Users', icon: '👥', color: AppColors.navy),
            StatCard(value: '23', label: 'Active Incidents', icon: '🚨', color: AppColors.red),
            StatCard(value: '156', label: 'Barangays Covered', icon: '📍', color: AppColors.teal),
            StatCard(value: '94%', label: 'System Uptime', icon: '📡', color: AppColors.green),
          ],
        ),
        const SizedBox(height: 18),
        TwoColumn(
          breakpoint: 940,
          left: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Incident Trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                ...[24, 36, 28, 42, 31, 44, 39].asMap().entries.map((entry) => _Bar(label: 'D${entry.key + 1}', value: entry.value, max: 50, color: AppColors.red)),
              ],
            ),
          ),
          right: _HotspotPreview(firestoreService: firestoreService),
        ),
      ],
    );
  }
}

class _HotspotPreview extends StatelessWidget {
  const _HotspotPreview({required this.firestoreService});

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Hotspot>>(
      stream: firestoreService.hotspots(),
      builder: (context, snapshot) {
        final hotspots = snapshot.data ?? const <Hotspot>[];
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Disease Hotspots', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              ...hotspots.map((hotspot) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: statusColor(hotspot.level).withOpacity(.12), foregroundColor: statusColor(hotspot.level), child: const Icon(Icons.coronavirus_rounded)),
                    title: Text('Brgy. ${hotspot.barangay}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('${hotspot.disease} · ${hotspot.cases} cases'),
                    trailing: StatusPill(label: hotspot.level),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _HotspotsAdmin extends StatelessWidget {
  const _HotspotsAdmin({required this.firestoreService});

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader(title: 'Disease Hotspots', subtitle: 'Cleaned Firestore collection: disease_hotspots with unique barangay + disease + weekStart records.'),
      const SizedBox(height: 18),
      _HotspotPreview(firestoreService: firestoreService),
    ]);
  }
}

class _UsersAdmin extends StatelessWidget {
  const _UsersAdmin({required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'User Verification Queue', subtitle: 'Approve or reject responder and professional account requests.'),
        const SizedBox(height: 18),
        StreamBuilder<List<AppUser>>(
          stream: firestoreService.pendingUsers(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? const <AppUser>[];
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Text('Pending Accounts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    StatusPill(label: '${users.length} PENDING', color: AppColors.amber),
                  ]),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No pending accounts.', style: TextStyle(color: AppColors.muted))))
                  else
                    ...users.map((target) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: AppColors.purple.withOpacity(.12), foregroundColor: AppColors.purple, child: Text(target.role.emoji)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(target.fullName, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  Text('${target.email} · ${target.role.label}', style: const TextStyle(color: AppColors.muted)),
                                ]),
                              ),
                              Wrap(spacing: 8, children: [
                                FilledButton(onPressed: () => firestoreService.updateUserStatus(userId: target.id, status: 'approved', actor: user), child: const Text('Approve')),
                                OutlinedButton(onPressed: () => firestoreService.updateUserStatus(userId: target.id, status: 'rejected', actor: user), child: const Text('Reject')),
                              ]),
                            ],
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReportsAdmin extends StatelessWidget {
  const _ReportsAdmin();

  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Reports & Analytics', subtitle: 'Prototype report board for incident outcomes, appointment load, and disease trends.'),
      SizedBox(height: 18),
      ResponsiveGrid(children: [
        StatCard(value: '74', label: 'Incident Reports', icon: '📄', color: AppColors.navy),
        StatCard(value: '18', label: 'Critical Outcomes', icon: '🚨', color: AppColors.red),
        StatCard(value: '326', label: 'Appointments', icon: '📅', color: AppColors.teal),
        StatCard(value: '6', label: 'High Risk Zones', icon: '🗺️', color: AppColors.amber),
      ]),
    ]);
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max, required this.color});

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: value / max, minHeight: 14, color: color, backgroundColor: color.withOpacity(.10)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}
