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
        ProfileSummaryCard(user: user),
        const SizedBox(height: 18),
        PageHeader(
          title: 'Citizen Dashboard',
          subtitle: 'Emergency assistance, care access, and local health monitoring.',
        ),
         const SizedBox(height: 20),
         Center(
           child: Material(
             color: Colors.transparent,
             child: InkWell(
               onTap: () => SOSModal.show(context, user: user, firestoreService: firestoreService),
               borderRadius: BorderRadius.circular(90),
               child: Container(
                   width: 130,
                   height: 130,
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: AppColors.red,
                     boxShadow: [BoxShadow(color: AppColors.red.withOpacity(.25), blurRadius: 24, offset: const Offset(0, 10))],
                   ),
                   child: const Center(
                     child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2, height: 1)),
                   )),
             ),
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
                // 'Check symptoms' quick action removed to simplify the Home view
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
