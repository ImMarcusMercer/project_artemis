import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class SymptomCheckerPage extends StatefulWidget {
  const SymptomCheckerPage({super.key, required this.user, required this.firestoreService, required this.onBookAppointment});

  final AppUser user;
  final FirestoreService firestoreService;
  final VoidCallback onBookAppointment;

  @override
  State<SymptomCheckerPage> createState() => _SymptomCheckerPageState();
}

class _SymptomCheckerPageState extends State<SymptomCheckerPage> {
  final _bodyAreaController = TextEditingController(text: 'Chest / respiratory');
  final _detailsController = TextEditingController();
  final _symptoms = <String>{'Cough', 'Fever'};
  SymptomResult? _result;
  bool _saving = false;

  final options = const [
    'Chest pain',
    'Breathing difficulty',
    'Severe bleeding',
    'Loss of consciousness',
    'Severe allergic reaction',
    'Fever',
    'Cough',
    'Headache',
    'Abdominal pain',
    'Dizziness',
  ];

  @override
  void dispose() {
    _bodyAreaController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  SymptomResult _triage() {
    final lower = _symptoms.map((s) => s.toLowerCase()).join(' ');
    if (lower.contains('chest pain') || lower.contains('breathing') || lower.contains('loss of consciousness') || lower.contains('severe bleeding')) {
      return const SymptomResult(
        severity: 'critical',
        specialty: 'Emergency Medicine',
        summary: 'Red-flag symptoms detected. This should be treated as an emergency until assessed by a qualified professional.',
        recommendations: ['Call emergency services or send SOS', 'Avoid self-transport if unstable', 'Prepare patient profile and medication/allergy information'],
      );
    }
    if (lower.contains('fever') && lower.contains('cough')) {
      return const SymptomResult(
        severity: 'moderate',
        specialty: 'Internal Medicine',
        summary: 'Symptoms suggest a respiratory infection pattern. Monitoring and consultation are recommended if symptoms persist or worsen.',
        recommendations: ['Monitor temperature and breathing', 'Hydrate and rest', 'Book consultation if fever persists beyond 2–3 days'],
      );
    }
    if (lower.contains('abdominal')) {
      return const SymptomResult(
        severity: 'high',
        specialty: 'Family Medicine / Gastroenterology',
        summary: 'Abdominal symptoms need evaluation if pain is severe, persistent, or associated with vomiting, fever, or dehydration.',
        recommendations: ['Track pain location and duration', 'Avoid heavy meals', 'Book consultation if persistent'],
      );
    }
    return const SymptomResult(
      severity: 'low',
      specialty: 'Family Medicine',
      summary: 'No immediate red flags were detected in this prototype triage. Continue monitoring and seek care if symptoms worsen.',
      recommendations: ['Rest and observe symptoms', 'Keep a symptom log', 'Book a routine consultation if needed'],
    );
  }

  Future<void> _runTriage() async {
    final result = _triage();
    setState(() {
      _result = result;
      _saving = true;
    });
    await widget.firestoreService.submitSymptomCheck(
      user: widget.user,
      symptoms: _symptoms.toList(),
      bodyArea: _bodyAreaController.text,
      result: result,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'AI Symptom Triage', subtitle: 'Prototype decision support only. This does not replace professional medical advice.'),
        const SizedBox(height: 18),
        TwoColumn(
          breakpoint: 900,
          left: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What are you feeling?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((symptom) {
                    final selected = _symptoms.contains(symptom);
                    return FilterChip(
                      selected: selected,
                      label: Text(symptom),
                      onSelected: (value) => setState(() => value ? _symptoms.add(symptom) : _symptoms.remove(symptom)),
                      selectedColor: AppColors.teal.withOpacity(.16),
                      checkmarkColor: AppColors.teal,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(controller: _bodyAreaController, decoration: const InputDecoration(labelText: 'Body part affected', prefixIcon: Icon(Icons.accessibility_new_rounded))),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailsController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(labelText: 'Additional symptom details', prefixIcon: Icon(Icons.notes_rounded)),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: _saving ? 'Saving result...' : 'Run Triage', icon: Icons.bolt_rounded, onPressed: _symptoms.isEmpty || _saving ? null : _runTriage, color: AppColors.teal),
              ],
            ),
          ),
          right: SectionCard(
            child: _result == null ? _emptyResult() : _resultView(_result!),
          ),
        ),
      ],
    );
  }

  Widget _emptyResult() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Triage Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 16),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: Column(
              children: [
                Text('⚡', style: TextStyle(fontSize: 54)),
                SizedBox(height: 12),
                Text('Select symptoms to generate a prototype triage summary.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultView(SymptomResult result) {
    final color = statusColor(result.severity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Triage Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            StatusPill(label: result.severity, color: color),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(18)),
          child: Text(result.summary, style: TextStyle(color: color, fontWeight: FontWeight.w800, height: 1.45)),
        ),
        const SizedBox(height: 16),
        Text('Recommended Specialty: ${result.specialty}', style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...result.recommendations.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ]),
            )),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Book Recommended Doctor', icon: Icons.calendar_month_rounded, onPressed: widget.onBookAppointment, color: AppColors.navy),
      ],
    );
  }
}
