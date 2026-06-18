import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/local_db_service.dart';
import 'services/sync_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/order_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/client_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wsohgkyrtskshbinlfeg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NzMzNTgsImV4cCI6MjA5NjQ0OTM1OH0.dI7gPifxB0PCojH-oYUAkPbTsIVrPtV82378mjmN6NE',
  );

  final supabaseService = SupabaseService(Supabase.instance.client);
  final localDbService = LocalDbService();
  final syncService = SyncService(supabaseService, localDbService);

  final authRepository = AuthRepository(supabaseService, localDbService);
  final clientRepository =
      ClientRepository(supabaseService, localDbService, syncService);
  final productRepository = ProductRepository(supabaseService, localDbService);
  final orderRepository =
      OrderRepository(supabaseService, localDbService, syncService);

  syncService.iniciarSyncAutomatico();

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseService>.value(value: supabaseService),
        Provider<LocalDbService>.value(value: localDbService),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientProvider(clientRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orderRepository),
        ),
      ],
      child: const DistriGolfApp(),
    ),
  );
}
