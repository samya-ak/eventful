import 'package:flutter/material.dart';
import 'screens/events_page.dart';
import 'l10n/app_strings.dart';
import 'services/supabase_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await SupabaseConfig.load();
  print('Environment variables loaded successfully');

  // Initialize Supabase
  await SupabaseService.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  print('Supabase initialized successfully');

  // Check connection
  final isConnected = await SupabaseService.checkConnection();
  print('Supabase connection check: ${isConnected ? 'SUCCESS' : 'FAILED'}');

  // Create storage bucket if it doesn't exist
  await SupabaseService.createBucketIfNotExists();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const EventsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
