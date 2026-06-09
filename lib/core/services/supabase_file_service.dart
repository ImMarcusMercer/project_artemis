import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap/backend_bootstrap.dart';

class SupabaseFileService {
  SupabaseFileService(this.backendState);

  final BackendState backendState;

  bool get ready => backendState.supabaseReady;

  String get bucket => dotenv.env['SUPABASE_STORAGE_BUCKET'] ?? 'artemis-files';

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
  }) async {
    if (!ready) {
      throw Exception('Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY in .env.');
    }

    final storage = Supabase.instance.client.storage.from(bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return storage.getPublicUrl(path);
  }
}
