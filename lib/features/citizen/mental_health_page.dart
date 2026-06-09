import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class MentalHealthPage extends StatefulWidget {
  const MentalHealthPage({super.key, required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  @override
  State<MentalHealthPage> createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage> {
  final _journalController = TextEditingController();
  final _done = <String>{'Breathing exercise'};
  double _mood = 7;
  bool _saving = false;

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.firestoreService.saveMentalHealthSession(
      user: widget.user,
      moodScore: _mood.round(),
      moodLabel: _label,
      journalEntry: _journalController.text.trim(),
      exercisesDone: _done.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.firestoreService.ready ? 'Mental health session saved.' : 'Mock mental health session saved.')),
    );
  }

  String get _label {
    if (_mood <= 3) return 'Needs support';
    if (_mood <= 6) return 'Neutral';
    return 'Positive';
  }

  @override
  Widget build(BuildContext context) {
    const exercises = ['Breathing exercise', 'Grounding 5-4-3-2-1', 'Gratitude note', 'Body scan', 'Short walk'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Mental Wellness Hub', subtitle: 'Mood tracking, journaling, and simple self-care exercises.'),
        const SizedBox(height: 18),
        TwoColumn(
          breakpoint: 900,
          left: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mood Check-in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('${_mood.round()}/10 · $_label', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: statusColor(_label == 'Positive' ? 'low' : _label == 'Neutral' ? 'moderate' : 'high'))),
                Slider(value: _mood, min: 1, max: 10, divisions: 9, label: _mood.round().toString(), onChanged: (value) => setState(() => _mood = value)),
                const SizedBox(height: 12),
                TextField(
                  controller: _journalController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Journal entry', hintText: 'Write what you feel today...', prefixIcon: Icon(Icons.edit_note_rounded)),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: _saving ? 'Saving...' : 'Save Check-in', icon: Icons.save_rounded, onPressed: _saving ? null : _save, color: AppColors.purple),
              ],
            ),
          ),
          right: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Guided Exercises', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ...exercises.map((exercise) {
                  final checked = _done.contains(exercise);
                  return CheckboxListTile(
                    value: checked,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.purple,
                    title: Text(exercise, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(_exerciseDescription(exercise)),
                    onChanged: (value) => setState(() => value == true ? _done.add(exercise) : _done.remove(exercise)),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.navy.withOpacity(.06), borderRadius: BorderRadius.circular(18)),
                  child: const Text('For emergencies or self-harm risk, contact local emergency services or a trusted person immediately.', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _exerciseDescription(String exercise) {
    switch (exercise) {
      case 'Breathing exercise':
        return 'Inhale 4 seconds, hold 4, exhale 6.';
      case 'Grounding 5-4-3-2-1':
        return 'Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.';
      case 'Gratitude note':
        return 'Write one specific thing that helped you today.';
      case 'Body scan':
        return 'Notice tension from head to toe without judging it.';
      default:
        return 'A brief physical reset to clear stress.';
    }
  }
}
