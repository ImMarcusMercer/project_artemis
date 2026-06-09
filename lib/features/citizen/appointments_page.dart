import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key, required this.user, required this.firestoreService});

  final AppUser user;
  final FirestoreService firestoreService;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final _reasonController = TextEditingController(text: 'Consultation after symptom triage');
  final _contactController = TextEditingController();
  String _provider = 'Dr. Andrea Reyes';
  String _providerEmail = 'doctor@sagip.ph';
  String _specialty = 'Internal Medicine';
  String _facility = 'Batangas Medical Center';
  String _type = 'telemedicine';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 30);
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _contactController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    setState(() => _booking = true);
    final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final appointment = Appointment(
      id: 'new',
      patientId: widget.user.id,
      providerId: null,
      providerEmail: _providerEmail,
      patientName: widget.user.fullName,
      providerName: _provider,
      providerSpecialty: _specialty,
      facilityName: _facility,
      scheduledAt: scheduled,
      type: _type,
      status: 'pending',
      reason: _reasonController.text.trim(),
      contactNumber: _contactController.text.trim(),
    );
    await widget.firestoreService.bookAppointment(appointment);
    if (!mounted) return;
    setState(() => _booking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.firestoreService.ready ? 'Appointment request saved.' : 'Mock appointment request created.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Appointments', subtitle: 'Book telemedicine or in-person consultation and track request status.'),
        const SizedBox(height: 18),
        TwoColumn(
          breakpoint: 980,
          leftFlex: 5,
          rightFlex: 6,
          left: _bookingForm(),
          right: _appointmentList(),
        ),
      ],
    );
  }

  Widget _bookingForm() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Book New Appointment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _provider,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: const [
              DropdownMenuItem(value: 'Dr. Andrea Reyes', child: Text('Dr. Andrea Reyes · Internal Medicine')),
              DropdownMenuItem(value: 'Dr. Miguel Ramos', child: Text('Dr. Miguel Ramos · Family Medicine')),
              DropdownMenuItem(value: 'Dr. Liza Mendoza', child: Text('Dr. Liza Mendoza · Psychiatry')),
            ],
            onChanged: (value) => setState(() {
              _provider = value ?? _provider;
              _specialty = _provider.contains('Miguel')
                  ? 'Family Medicine'
                  : _provider.contains('Liza')
                      ? 'Psychiatry'
                      : 'Internal Medicine';
              _providerEmail = _provider.contains('Miguel')
                  ? 'miguel@sagip.ph'
                  : _provider.contains('Liza')
                      ? 'liza@sagip.ph'
                      : 'doctor@sagip.ph';
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _facility,
            decoration: const InputDecoration(labelText: 'Facility'),
            items: const [
              DropdownMenuItem(value: 'Batangas Medical Center', child: Text('Batangas Medical Center')),
              DropdownMenuItem(value: 'Batangas City Health Office', child: Text('Batangas City Health Office')),
              DropdownMenuItem(value: 'San Jose Barangay Clinic', child: Text('San Jose Barangay Clinic')),
            ],
            onChanged: (value) => setState(() => _facility = value ?? _facility),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'telemedicine', label: Text('Telemedicine'), icon: Icon(Icons.video_call_rounded)),
              ButtonSegment(value: 'in-person', label: Text('In-person'), icon: Icon(Icons.local_hospital_rounded)),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text('${_date.month}/${_date.day}/${_date.year}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(_time.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact number', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _reasonController, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Reason for visit', prefixIcon: Icon(Icons.notes_rounded))),
          const SizedBox(height: 16),
          PrimaryButton(label: _booking ? 'Booking...' : 'Request Appointment', icon: Icons.send_rounded, onPressed: _booking ? null : _book, color: AppColors.teal),
        ],
      ),
    );
  }

  Widget _appointmentList() {
    return StreamBuilder<List<Appointment>>(
      stream: widget.firestoreService.appointmentsForUser(widget.user),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Appointment>[];
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('My Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                  StatusPill(label: '${items.length} TOTAL', color: AppColors.navy),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('No appointments yet.', style: TextStyle(color: AppColors.muted))),
                )
              else
                ...items.map((appointment) => _AppointmentTile(appointment: appointment)),
            ],
          ),
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(appointment.providerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
              StatusPill(label: appointment.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('${appointment.providerSpecialty} · ${appointment.facilityName}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(friendlyDateTime(appointment.scheduledAt), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(appointment.reason, style: const TextStyle(height: 1.4)),
          if (appointment.teleconsultUrl != null) ...[
            const SizedBox(height: 8),
            Text('Teleconsult link: ${appointment.teleconsultUrl}', style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }
}
