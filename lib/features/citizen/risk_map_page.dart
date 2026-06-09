import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class RiskMapPage extends StatelessWidget {
  const RiskMapPage({super.key, required this.firestoreService});

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Health & Risk Map', subtitle: 'Live hazard, weather, and disease monitoring mockup for Batangas City.'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.amber.withOpacity(.40))),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.amber),
              SizedBox(width: 10),
              Expanded(child: Text('AREA STATUS: CAUTION · Moderate rain expected. Flood-prone areas may be affected.', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: const [
            StatCard(value: '12 mm/h', label: 'Rainfall', icon: '💧', color: AppColors.blue),
            StatCard(value: '18 km/h', label: 'Wind Speed', icon: '💨', color: AppColors.amber),
            StatCard(value: 'Good', label: 'Visibility', icon: '👁️', color: AppColors.green),
            StatCard(value: 'Moderate', label: 'Flood Risk', icon: '🌊', color: AppColors.red),
          ],
        ),
        const SizedBox(height: 18),
        TwoColumn(
          breakpoint: 1000,
          leftFlex: 7,
          rightFlex: 4,
          left: const _MockMap(),
          right: _HotspotList(firestoreService: firestoreService),
        ),
      ],
    );
  }
}

class _MockMap extends StatelessWidget {
  const _MockMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFC7D9FF), Color(0xFFE4EAFF)]),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _MapPainter()),
          const _MapMarker(top: .26, left: .35, label: '47 cases', emoji: '🦠', color: AppColors.red),
          const _MapMarker(top: .53, left: .66, label: 'Flood', emoji: '🌊', color: AppColors.amber),
          const _MapMarker(top: .70, left: .25, label: 'Clinic', emoji: '🏥', color: AppColors.teal),
          const _MapMarker(top: .34, left: .76, label: 'Hospital', emoji: '🏥', color: AppColors.green),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.navy.withOpacity(.85), borderRadius: BorderRadius.circular(12)),
              child: const Text('Batangas City', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.navy.withOpacity(.20)
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = AppColors.navy.withOpacity(.12)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * .50)
      ..quadraticBezierTo(size.width * .25, size.height * .38, size.width * .50, size.height * .50)
      ..quadraticBezierTo(size.width * .75, size.height * .62, size.width, size.height * .50);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * .50, 0)
      ..quadraticBezierTo(size.width * .56, size.height * .25, size.width * .50, size.height * .50)
      ..quadraticBezierTo(size.width * .44, size.height * .75, size.width * .50, size.height);
    canvas.drawPath(path2, roadPaint);

    canvas.drawLine(Offset(0, size.height * .25), Offset(size.width, size.height * .22), thinRoad);
    canvas.drawLine(Offset(0, size.height * .75), Offset(size.width, size.height * .76), thinRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.top, required this.left, required this.label, required this.emoji, required this.color});

  final double top;
  final double left;
  final String label;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FractionallySizedBox(
        alignment: Alignment(left * 2 - 1, top * 2 - 1),
        widthFactor: .18,
        heightFactor: .18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 23, backgroundColor: color, child: Text(emoji, style: const TextStyle(fontSize: 20))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(999)),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotspotList extends StatelessWidget {
  const _HotspotList({required this.firestoreService});

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
              const Text('Active Risk Zones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...hotspots.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 6, backgroundColor: statusColor(item.level)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Brgy. ${item.barangay}', style: const TextStyle(fontWeight: FontWeight.w900)),
                              Text('${item.disease} · ${item.cases} cases · trend ${item.trend}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        StatusPill(label: item.level),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
