import 'package:flutter/material.dart';

import '../../bootstrap/backend_bootstrap.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/supabase_file_service.dart';
import '../../core/widgets/resq_widgets.dart';
import '../admin/admin_dashboard.dart';
import '../citizen/appointments_page.dart';
import '../citizen/citizen_home.dart';
import '../citizen/clinic_finder_page.dart';
import '../citizen/mental_health_page.dart';
import '../citizen/risk_map_page.dart';
import '../citizen/symptom_checker.dart';
import '../professional/professional_dashboard.dart';
import '../responder/responder_dashboard.dart';

class NavItem {
  const NavItem({required this.id, required this.label, required this.icon, required this.description});

  final String id;
  final String label;
  final IconData icon;
  final String description;
}

class WebLayout extends StatefulWidget {
  const WebLayout({
    super.key,
    required this.user,
    required this.backendState,
    required this.firestoreService,
    required this.fileService,
    required this.onLogout,
    required this.onUserUpdated,
  });

  final AppUser user;
  final BackendState backendState;
  final FirestoreService firestoreService;
  final SupabaseFileService fileService;
  final VoidCallback onLogout;
  final ValueChanged<AppUser> onUserUpdated;

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  late String _activeTab;

  Map<AppRole, List<NavItem>> get nav => {
        AppRole.citizen: const [
          NavItem(id: 'home', label: 'Home', icon: Icons.dashboard_rounded, description: 'Dashboard overview'),
          NavItem(id: 'symptoms', label: 'Symptom Triage', icon: Icons.monitor_heart_rounded, description: 'AI symptom checker'),
          NavItem(id: 'appointments', label: 'Appointments', icon: Icons.calendar_month_rounded, description: 'My bookings'),
          NavItem(id: 'mental', label: 'Mental Wellness', icon: Icons.psychology_rounded, description: 'Mental health hub'),
          NavItem(id: 'clinics', label: 'Find Clinic', icon: Icons.local_hospital_rounded, description: 'Nearby care'),
          NavItem(id: 'map', label: 'Risk Map', icon: Icons.map_rounded, description: 'Health & hazards'),
        ],
        AppRole.responder: const [
          NavItem(id: 'alerts', label: 'Live Alerts', icon: Icons.sos_rounded, description: 'Active incidents'),
          NavItem(id: 'reports', label: 'Reports', icon: Icons.assignment_rounded, description: 'Incident reports'),
        ],
        AppRole.professional: const [
          NavItem(id: 'queue', label: 'Patient Queue', icon: Icons.groups_rounded, description: 'Waiting patients'),
          NavItem(id: 'schedule', label: 'Schedule', icon: Icons.event_available_rounded, description: 'Appointments'),
          NavItem(id: 'consult', label: 'Consult', icon: Icons.medical_services_rounded, description: 'Consultation'),
        ],
        AppRole.admin: const [
          NavItem(id: 'overview', label: 'Overview', icon: Icons.dashboard_customize_rounded, description: 'System overview'),
          NavItem(id: 'hotspots', label: 'Hotspots', icon: Icons.map_rounded, description: 'Disease data'),
          NavItem(id: 'reports', label: 'Reports', icon: Icons.analytics_rounded, description: 'Analytics'),
          NavItem(id: 'users', label: 'Users', icon: Icons.verified_user_rounded, description: 'Approvals'),
        ],
      };

  @override
  void initState() {
    super.initState();
    _activeTab = nav[widget.user.role]!.first.id;
  }

  @override
  void didUpdateWidget(covariant WebLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.role != widget.user.role) {
      _activeTab = nav[widget.user.role]!.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = nav[widget.user.role]!;
    final wide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: wide ? null : Drawer(child: _Sidebar(items: items, activeTab: _activeTab, onChanged: _setTab, user: widget.user, onLogout: widget.onLogout)),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 292,
              child: _Sidebar(items: items, activeTab: _activeTab, onChanged: _setTab, user: widget.user, onLogout: widget.onLogout),
            ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  user: widget.user,
                  backendState: widget.backendState,
                  onLogout: widget.onLogout,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _activePage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : Builder(
              builder: (context) {
                final visibleItems = items.take(4).toList();
                final rawIndex = visibleItems.indexWhere((item) => item.id == _activeTab);
                final selectedIndex = rawIndex < 0 ? 0 : rawIndex;
                return NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _setTab(visibleItems[index].id),
                  destinations: visibleItems.map((item) => NavigationDestination(icon: Icon(item.icon), label: item.label)).toList(),
                );
              },
            ),
    );
  }

  void _setTab(String id) {
    setState(() => _activeTab = id);
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) Navigator.of(context).pop();
  }

  Widget _activePage() {
    switch (widget.user.role) {
      case AppRole.citizen:
        switch (_activeTab) {
          case 'symptoms':
            return SymptomCheckerPage(user: widget.user, firestoreService: widget.firestoreService, onBookAppointment: () => _setTab('appointments'));
          case 'appointments':
            return AppointmentsPage(user: widget.user, firestoreService: widget.firestoreService);
          case 'mental':
            return MentalHealthPage(user: widget.user, firestoreService: widget.firestoreService);
          case 'clinics':
            return ClinicFinderPage(firestoreService: widget.firestoreService);
          case 'map':
            return RiskMapPage(firestoreService: widget.firestoreService);
          default:
            return CitizenHome(user: widget.user, firestoreService: widget.firestoreService, onNavigate: _setTab);
        }
      case AppRole.responder:
        return ResponderDashboard(user: widget.user, firestoreService: widget.firestoreService, mode: _activeTab);
      case AppRole.professional:
        return ProfessionalDashboard(user: widget.user, firestoreService: widget.firestoreService, mode: _activeTab);
      case AppRole.admin:
        return AdminDashboard(user: widget.user, firestoreService: widget.firestoreService, mode: _activeTab);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user, required this.backendState, required this.onLogout});

  final AppUser user;
  final BackendState backendState;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: Scaffold.maybeOf(context)?.openDrawer,
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good day, ${user.fullName}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(
                  backendState.isMockMode ? 'Mock mode · Firebase not configured' : 'Firebase Auth + Firestore connected',
                  style: TextStyle(color: backendState.isMockMode ? AppColors.amber : AppColors.green, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') onLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')), 
              PopupMenuItem(value: 'logout', child: Text('Logout')), 
            ],
            child: CircleAvatar(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              child: Text(user.initials, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.activeTab,
    required this.onChanged,
    required this.user,
    required this.onLogout,
  });

  final List<NavItem> items;
  final String activeTab;
  final ValueChanged<String> onChanged;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('⚕️', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ResQ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text('Artemis v1.1', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.white, foregroundColor: AppColors.navy, child: Text(user.initials, style: const TextStyle(fontWeight: FontWeight.w900))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          Text('${user.role.emoji} ${user.role.label} · ${user.status}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final active = item.id == activeTab;
                  return ListTile(
                    selected: active,
                    selectedTileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    leading: Icon(item.icon, color: active ? AppColors.navy : Colors.white70),
                    title: Text(item.label, style: TextStyle(color: active ? AppColors.navy : Colors.white, fontWeight: FontWeight.w900)),
                    subtitle: Text(item.description, style: TextStyle(color: active ? AppColors.muted : Colors.white54, fontSize: 12)),
                    onTap: () => onChanged(item.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                leading: const Icon(Icons.logout_rounded, color: Colors.white70),
                title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
