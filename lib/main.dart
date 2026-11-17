import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/navigation/onglets_page.dart';
import 'core/theme/app_theme.dart';
import 'features/events/data/event_repository.dart';
import 'features/events/logic/events_cubit.dart';
import 'features/partners/data/partner_repository.dart';
import 'features/partners/logic/partners_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Après `flutterfire configure` : ajouter `options: DefaultFirebaseOptions.currentPlatform`.
  await Firebase.initializeApp();
  runApp(ParquetApp(partnerRepository: PartnerRepository(), eventRepository: EventRepository()));
}

class ParquetApp extends StatelessWidget {
  const ParquetApp({super.key, required this.partnerRepository, required this.eventRepository});

  /// Injectés pour que les tests passent de faux repositories.
  final PartnerRepository partnerRepository;
  final EventRepository eventRepository;

  @override
  Widget build(BuildContext context) {
    // Les Cubits sont au-dessus du Navigator : liste et détail partagent le même état.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PartnersCubit(partnerRepository)..charger()),
        BlocProvider(create: (_) => EventsCubit(eventRepository)..charger()),
      ],
      child: MaterialApp(
        title: 'Parquet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const OngletsPage(),
      ),
    );
  }
}
