import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:liftlink/app.dart';
import 'package:liftlink/core/config/supabase_config.dart';
import 'package:liftlink/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    // Notification initialization is optional
    debugPrint('Notification initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: LiftLinkApp(),
    ),
  );
}
