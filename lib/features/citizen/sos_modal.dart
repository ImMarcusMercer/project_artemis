import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class SOSModal extends StatefulWidget {
  const SOSModal({super.key, required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  static Future<void> show(BuildContext context, {required AppUser user, required FirestoreService firestoreService}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SOSModal(user: user, firestoreService: firestoreService),
    );
  }

  @override
  State<SOSModal> createState() => _SOSModalState();
}

class _SOSModalState extends State<SOSModal> {
  final _messageController = TextEditingController(text: 'Emergency assistance needed. Please dispatch responder immediately.');
  final _addressController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.user.address ?? 'Current location unavailable. Enter address manually.';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await widget.firestoreService.createSosAlert(
      user: widget.user,
      message: _messageController.text.trim(),
      address: _addressController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _sentView(context) : _confirmView(context),
        ),
      ),
    );
  }

  Widget _confirmView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: AppColors.red.withOpacity(.12), shape: BoxShape.circle),
          child: const Icon(Icons.sos_rounded, color: AppColors.red, size: 46),
        ),
        const SizedBox(height: 16),
        const Text('Send SOS Alert?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          'This will create an active emergency incident and notify available responders/admin monitoring screens.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Location / address', prefixIcon: Icon(Icons.location_on_outlined)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Emergency message', prefixIcon: Icon(Icons.message_outlined)),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: _sending ? 'Sending...' : 'Send SOS',
                icon: Icons.warning_rounded,
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sentView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: AppColors.green.withOpacity(.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 48),
        ),
        const SizedBox(height: 16),
        const Text('SOS Alert Sent', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          widget.firestoreService.ready
              ? 'Your alert has been stored in Firestore and an incident was opened for dispatch.'
              : 'Mock mode: the SOS flow was simulated. Add Firebase credentials to store alerts.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Close', icon: Icons.done_rounded, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
