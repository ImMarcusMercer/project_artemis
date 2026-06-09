import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class ResponderDashboard extends StatelessWidget {
  const ResponderDashboard({super.key, required this.user, required this.firestoreService, required this.mode});

  final AppUser user;
  final FirestoreService firestoreService;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return mode == 'reports' ? _ReportsView(user: user, firestoreService: firestoreService) : _AlertsView(user: user, firestoreService: firestoreService);
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView({required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSummaryCard(user: user),
        const SizedBox(height: 18),
        const PageHeader(title: 'Live Emergency Alerts', subtitle: 'Dispatch-ready incident feed for EMS responders.'),
        const SizedBox(height: 18),
        ResponsiveGrid(
          children: const [
            StatCard(value: '2', label: 'Active Alerts', icon: '🚨', color: AppColors.red),
            StatCard(value: '1', label: 'Assigned Unit', icon: '🚑', color: AppColors.blue),
            StatCard(value: '8.4m', label: 'Average Response', icon: '⏱️', color: AppColors.teal),
            StatCard(value: 'Online', label: 'Duty Status', icon: '📡', color: AppColors.green),
          ],
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<Incident>>(
          stream: firestoreService.activeIncidents(responder: user),
          builder: (context, snapshot) {
            final incidents = snapshot.data ?? const <Incident>[];
            return Column(
              children: incidents.map((incident) => _IncidentCard(incident: incident, user: user, firestoreService: firestoreService)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.user, required this.firestoreService});

  final Incident incident;
  final AppUser user;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(incident.priority);
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(.12), foregroundColor: color, child: const Icon(Icons.sos_rounded)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incident.type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(incident.address, style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              StatusPill(label: incident.priority, color: color),
              const SizedBox(width: 8),
              StatusPill(label: incident.status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Meta(icon: Icons.person_rounded, text: incident.patientInfo ?? 'No patient snapshot'),
              _Meta(icon: Icons.timer_rounded, text: friendlyDateTime(incident.reportedAt)),
              _Meta(icon: Icons.location_city_rounded, text: incident.barangay ?? 'Unspecified barangay'),
            ],
          ),
          if (incident.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
              child: Text(incident.notes!, style: const TextStyle(height: 1.4)),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PrimaryButton(
                label: incident.status == 'pending' ? 'Accept Dispatch' : 'Update: En Route',
                icon: Icons.navigation_rounded,
                fullWidth: false,
                onPressed: () async {
                  if (incident.status == 'pending') {
                    await firestoreService.acceptIncident(incidentId: incident.id, responder: user);
                  } else {
                    await firestoreService.updateIncidentStatus(incidentId: incident.id, status: 'in-progress');
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(firestoreService.ready ? 'Incident updated.' : 'Mock incident updated.')));
                  }
                },
                color: AppColors.teal,
              ),
              OutlinedButton.icon(
                onPressed: () => showDialog(context: context, builder: (_) => _ReportDialog(incident: incident, user: user, firestoreService: firestoreService)),
                icon: const Icon(Icons.assignment_turned_in_rounded),
                label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('File Report')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16, color: AppColors.muted), const SizedBox(width: 5), Text(text, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.incident, required this.user, required this.firestoreService});

  final Incident incident;
  final AppUser user;
  final FirestoreService firestoreService;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _actionsController = TextEditingController(text: 'Arrived at scene, assessed patient, provided first aid, and coordinated transport.');
  String _outcome = 'Stable';
  bool _saving = false;

  @override
  void dispose() {
    _actionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await widget.firestoreService.submitIncidentReport(
      incident: widget.incident,
      responder: widget.user,
      actionsTaken: _actionsController.text.trim(),
      outcome: _outcome,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.firestoreService.ready ? 'Incident report filed.' : 'Mock report filed.')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File Incident Report'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _actionsController, minLines: 4, maxLines: 6, decoration: const InputDecoration(labelText: 'Actions taken')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _outcome,
              decoration: const InputDecoration(labelText: 'Patient outcome'),
              items: const ['Stable', 'Critical', 'Deceased', 'Unknown'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) => setState(() => _outcome = value ?? _outcome),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Saving...' : 'Submit Report')),
      ],
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView({required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSummaryCard(user: user),
        const SizedBox(height: 18),
        const PageHeader(title: 'Responder Reports', subtitle: 'Post-incident report submission is available from each live incident card.'),
        const SizedBox(height: 18),
        const SectionCard(
          child: Text('Reports are stored in the incident_reports Firestore collection after filing. This page is reserved for report history and export filters.'),
        ),
      ],
    );
  }
}
