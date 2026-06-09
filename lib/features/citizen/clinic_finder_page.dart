import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/resq_widgets.dart';

class ClinicFinderPage extends StatelessWidget {
  const ClinicFinderPage({super.key, required this.firestoreService});

  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Find Clinic', subtitle: 'Browse available hospitals, RHUs, and barangay health stations.'),
        const SizedBox(height: 18),
        StreamBuilder<List<Facility>>(
          stream: firestoreService.facilities(),
          builder: (context, snapshot) {
            final facilities = snapshot.data ?? const <Facility>[];
            return ResponsiveGrid(
              minTileWidth: 310,
              children: facilities
                  .map((facility) => SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: AppColors.teal.withOpacity(.10), foregroundColor: AppColors.teal, child: const Icon(Icons.local_hospital_rounded)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(facility.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            StatusPill(label: facility.type, color: AppColors.navy),
                            const SizedBox(height: 10),
                            Text(facility.address, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                            const SizedBox(height: 8),
                            Text('${facility.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
                            const Spacer(),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: facility.services.take(3).map((service) => StatusPill(label: service, color: AppColors.green)).toList(),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
