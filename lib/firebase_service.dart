// Backward-compatible wrapper kept for older imports from Artemis v1.0.
// New code uses bootstrap/backend_bootstrap.dart.
import 'bootstrap/backend_bootstrap.dart';

Future<BackendState> initializeFirebase() => BackendBootstrap.initialize();
