import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';
import 'sos_modal.dart';

class CitizenHome extends StatelessWidget {
  const CitizenHome({super.key, required this.user, required this.firestoreService, required this.onNavigate});

  final AppUser user;
  final FirestoreService firestoreService;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Citizen Dashboard',
          subtitle: 'Emergency assistance, care access, symptom triage, and local health monitoring.',
          trailing: PrimaryButton(
            label: 'SOS',
            icon: Icons.sos_rounded,
            fullWidth: false,
            onPressed: () => SOSModal.show(context, user: user, firestoreService: firestoreService),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [AppColors.red, AppColors.redDark]),
            boxShadow: [BoxShadow(color: AppColors.red.withOpacity(.25), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need urgent help?', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text('Tap SOS to open a dispatch-ready emergency alert with your profile and location.', style: TextStyle(color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () => SOSModal.show(context, user: user, firestoreService: firestoreService),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
                child: const Text('SEND SOS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ResponsiveGrid(
          children: const [
            StatCard(value: 'Normal', label: 'Profile Risk', icon: '❤️', color: AppColors.green),
            StatCard(value: '2.4 km', label: 'Nearest Hospital', icon: '🏥', color: AppColors.teal),
            StatCard(value: '1', label: 'Upcoming Appointment', icon: '📅', color: AppColors.blue),
            StatCard(value: 'Moderate', label: 'Area Alert Level', icon: '⚠️', color: AppColors.amber),
          ],
        ),
        const SizedBox(height: 18),
        TwoColumn(
          breakpoint: 760,
          left: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _ActionTile(icon: Icons.monitor_heart_rounded, color: AppColors.teal, title: 'Check symptoms', subtitle: 'Run AI-assisted triage', onTap: () => onNavigate('symptoms')),
                _ActionTile(icon: Icons.calendar_month_rounded, color: AppColors.blue, title: 'Book appointment', subtitle: 'Request in-person or telemedicine care', onTap: () => onNavigate('appointments')),
                _ActionTile(icon: Icons.psychology_rounded, color: AppColors.purple, title: 'Mental wellness', subtitle: 'Mood check and exercises', onTap: () => onNavigate('mental')),
                _ActionTile(icon: Icons.local_hospital_rounded, color: AppColors.green, title: 'Find clinic', subtitle: 'Browse nearby facilities', onTap: () => onNavigate('clinics')),
              ],
            ),
          ),
          right: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Medical Snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _InfoRow(label: 'Full name', value: user.fullName),
                _InfoRow(label: 'Age / Sex', value: '${user.age ?? 'Not set'} / ${user.sex ?? 'Not set'}'),
                _InfoRow(label: 'Blood type', value: user.bloodType ?? 'Not set'),
                _InfoRow(label: 'Allergies', value: user.allergies ?? 'None declared'),
                _InfoRow(label: 'Emergency contact', value: user.emergencyContact ?? 'Not set'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.medicalConditions.isEmpty
                      ? [const StatusPill(label: 'NO CONDITIONS DECLARED', color: AppColors.green)]
                      : user.medicalConditions.map((item) => StatusPill(label: item, color: AppColors.teal)).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withOpacity(.10), foregroundColor: color, child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
