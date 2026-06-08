import 'package:flutter/material.dart';

import 'app/artemis_app.dart';
import 'bootstrap/backend_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backendState = await BackendBootstrap.initialize();
  runApp(ArtemisApp(backendState: backendState));
}
