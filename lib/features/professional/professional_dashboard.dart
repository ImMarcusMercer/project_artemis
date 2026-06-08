import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class ProfessionalDashboard extends StatelessWidget {
  const ProfessionalDashboard({super.key, required this.user, required this.firestoreService, required this.mode});

  final AppUser user;
  final FirestoreService firestoreService;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: firestoreService.appointmentsForUser(user),
      builder: (context, snapshot) {
        final appointments = snapshot.data ?? const <Appointment>[];
        final pending = appointments.where((a) => a.status == 'pending').length;
        final accepted = appointments.where((a) => a.status == 'accepted').length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: mode == 'consult' ? 'Active Consultation' : mode == 'schedule' ? 'Professional Schedule' : 'Patient Queue',
              subtitle: 'Review appointment requests, accept/decline bookings, and prepare consultation summaries.',
            ),
            const SizedBox(height: 18),
            ResponsiveGrid(
              children: [
                StatCard(value: pending.toString(), label: 'Pending Requests', icon: '🩺', color: AppColors.amber),
                StatCard(value: accepted.toString(), label: 'Accepted Today', icon: '📅', color: AppColors.green),
                const StatCard(value: '12', label: 'Patients Served', icon: '👥', color: AppColors.teal),
                const StatCard(value: '94%', label: 'Queue Completion', icon: '✅', color: AppColors.blue),
              ],
            ),
            const SizedBox(height: 18),
            if (mode == 'consult')
              _ConsultationPanel(appointment: appointments.isEmpty ? null : appointments.first, firestoreService: firestoreService)
            else
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode == 'schedule' ? 'Schedule' : 'Patient Queue', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    if (appointments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 45),
                        child: Center(child: Text('No appointment requests yet.', style: TextStyle(color: AppColors.muted))),
                      )
                    else
                      ...appointments.map((appointment) => _ProfessionalAppointmentTile(appointment: appointment, firestoreService: firestoreService)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProfessionalAppointmentTile extends StatelessWidget {
  const _ProfessionalAppointmentTile({required this.appointment, required this.firestoreService});

  final Appointment appointment;
  final FirestoreService firestoreService;

  Future<void> _status(BuildContext context, String status) async {
    await firestoreService.updateAppointmentStatus(
      appointmentId: appointment.id,
      status: status,
      declineReason: status == 'declined' ? 'Schedule unavailable. Please choose another time slot.' : null,
      teleconsultUrl: status == 'accepted' && appointment.type == 'telemedicine' ? 'https://meet.example.com/resq-${appointment.id}' : null,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(firestoreService.ready ? 'Appointment $status.' : 'Mock appointment $status.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(backgroundColor: AppColors.teal.withOpacity(.10), foregroundColor: AppColors.teal, child: const Icon(Icons.person_rounded)),
            const SizedBox(width: 10),
            Expanded(child: Text(appointment.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            StatusPill(label: appointment.status),
          ]),
          const SizedBox(height: 8),
          Text(appointment.reason, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Text('${appointment.type} · ${friendlyDateTime(appointment.scheduledAt)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (appointment.status == 'pending')
            Wrap(
              spacing: 10,
              children: [
                PrimaryButton(label: 'Accept', icon: Icons.check_rounded, fullWidth: false, color: AppColors.green, onPressed: () => _status(context, 'accepted')),
                OutlinedButton.icon(onPressed: () => _status(context, 'declined'), icon: const Icon(Icons.close_rounded), label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Decline'))),
              ],
            )
          else if (appointment.status == 'accepted')
            PrimaryButton(label: 'Mark Completed', icon: Icons.task_alt_rounded, fullWidth: false, color: AppColors.navy, onPressed: () => _status(context, 'completed')),
        ],
      ),
    );
  }
}

class _ConsultationPanel extends StatefulWidget {
  const _ConsultationPanel({required this.appointment, required this.firestoreService});

  final Appointment? appointment;
  final FirestoreService firestoreService;

  @override
  State<_ConsultationPanel> createState() => _ConsultationPanelState();
}

class _ConsultationPanelState extends State<_ConsultationPanel> {
  final _subjective = TextEditingController(text: 'Patient reports cough, fever, and fatigue for two days.');
  final _objective = TextEditingController(text: 'No severe respiratory distress reported. Temperature monitoring advised.');
  final _assessment = TextEditingController(text: 'Likely respiratory infection. Rule out complications if symptoms worsen.');
  final _plan = TextEditingController(text: 'Hydration, rest, fever monitoring, and follow-up if fever persists.');

  @override
  void dispose() {
    _subjective.dispose();
    _objective.dispose();
    _assessment.dispose();
    _plan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOAP Consultation Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            appointment == null ? 'No active appointment selected. Demo SOAP form shown.' : '${appointment.patientName} · ${appointment.reason}',
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _SoapField(label: 'Subjective', controller: _subjective),
          _SoapField(label: 'Objective', controller: _objective),
          _SoapField(label: 'Assessment', controller: _assessment),
          _SoapField(label: 'Plan', controller: _plan),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.teal.withOpacity(.08), borderRadius: BorderRadius.circular(18)),
            child: const Text(
              'AI Clinical Summary: Patient symptoms appear non-critical based on available data. Recommend outpatient monitoring and escalation if breathing difficulty, chest pain, persistent high fever, or dehydration appears.',
              style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800, height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save Consultation Note', icon: Icons.save_rounded, onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation note save flow prepared for consultation_notes collection.')));
          }, color: AppColors.teal),
        ],
      ),
    );
  }
}

class _SoapField extends StatelessWidget {
  const _SoapField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.notes_rounded)),
      ),
    );
  }
}
