import 'package:flutter/material.dart';

import '../bootstrap/backend_bootstrap.dart';
import '../core/models/app_models.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/supabase_file_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/landing/landing_page.dart';
import '../features/shell/web_layout.dart';
import 'theme/app_theme.dart';

class ArtemisApp extends StatefulWidget {
  const ArtemisApp({super.key, required this.backendState});

  final BackendState backendState;

  @override
  State<ArtemisApp> createState() => _ArtemisAppState();
}

class _ArtemisAppState extends State<ArtemisApp> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final SupabaseFileService _fileService;

  AppUser? _currentUser;
  bool _showLanding = true;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(widget.backendState);
    _firestoreService = FirestoreService(widget.backendState);
    _fileService = SupabaseFileService(widget.backendState);
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await _authService.currentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _showLanding = user == null;
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artemis ResQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _checkingSession
          ? const _BootScreen()
          : _currentUser == null
              ? _showLanding
                  ? LandingPage(
                      backendState: widget.backendState,
                      onGetStarted: () => setState(() => _showLanding = false),
                    )
                  : AuthScreen(
                      backendState: widget.backendState,
                      authService: _authService,
                      onBack: () => setState(() => _showLanding = true),
                      onAuthenticated: (user) => setState(() {
                        _currentUser = user;
                        _showLanding = false;
                      }),
                    )
              : WebLayout(
                  user: _currentUser!,
                  backendState: widget.backendState,
                  firestoreService: _firestoreService,
                  fileService: _fileService,
                  onUserUpdated: (user) => setState(() => _currentUser = user),
                  onLogout: () async {
                    await _authService.signOut();
                    if (!mounted) return;
                    setState(() {
                      _currentUser = null;
                      _showLanding = true;
                    });
                  },
                ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
