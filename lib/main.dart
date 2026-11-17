import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/navigation/onglets_page.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/logic/auth_state.dart';
import 'features/auth/ui/lancement_page.dart';
import 'features/events/data/event_repository.dart';
import 'features/events/logic/events_cubit.dart';
import 'features/partners/data/partner_repository.dart';
import 'features/partners/logic/partners_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Après `flutterfire configure` : ajouter `options: DefaultFirebaseOptions.currentPlatform`.
  await Firebase.initializeApp();
  runApp(
    ParquetApp(
      authRepository: AuthRepository(),
      partnerRepository: PartnerRepository(),
      eventRepository: EventRepository(),
    ),
  );
}

class ParquetApp extends StatelessWidget {
  const ParquetApp({
    super.key,
    required this.authRepository,
    required this.partnerRepository,
    required this.eventRepository,
  });

  /// Injectés pour que les tests passent de faux repositories.
  final AuthRepository authRepository;
  final PartnerRepository partnerRepository;
  final EventRepository eventRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authRepository)..demarrer()),
        // Annuaire public : un seul Cubit pour toute la vie de l'app.
        BlocProvider(create: (_) => PartnersCubit(partnerRepository)..charger()),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, auth) {
          // La clé recrée l'app à chaque connexion ou déconnexion : pile d'écrans vidée, onglets du nouveau rôle.
          final app = MaterialApp(
            key: ValueKey(switch (auth) {
              AuthInconnu() => 'lancement',
              AuthVisiteur() => 'visiteur',
              AuthConnecte(:final session) => session.uid,
            }),
            title: 'Parquet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: switch (auth) {
              AuthInconnu() => const LancementPage(),
              AuthVisiteur() => const OngletsPage(),
              AuthConnecte(:final session) => OngletsPage(session: session),
            },
          );
          // Événements réservés aux comptes connectés : Cubit créé à la connexion, fermé à la déconnexion,
          // donc jamais les réponses d'un autre compte. Au-dessus du Navigator pour la liste et le détail.
          return switch (auth) {
            AuthConnecte(:final session) => BlocProvider(
              key: ValueKey(session.uid),
              create: (_) => EventsCubit(eventRepository)..charger(),
              child: app,
            ),
            _ => app,
          };
        },
      ),
    );
  }
}
