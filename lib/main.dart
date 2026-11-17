import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/onglets_page.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/admin/data/verrou_repository.dart';
import 'features/admin/logic/admin_cubit.dart';
import 'features/admin/logic/verrou_cubit.dart';
import 'features/admin/ui/ecran_verrou.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/logic/auth_state.dart';
import 'features/auth/ui/lancement_page.dart';
import 'features/events/data/event_repository.dart';
import 'features/events/logic/events_cubit.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/partners/data/partner_repository.dart';
import 'features/partners/logic/partners_cubit.dart';
import 'features/partners/logic/profile_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Après `flutterfire configure` : ajouter `options: DefaultFirebaseOptions.currentPlatform`.
  await Firebase.initializeApp();
  runApp(
    ParquetApp(
      authRepository: AuthRepository(),
      partnerRepository: PartnerRepository(),
      eventRepository: EventRepository(),
      adminRepository: AdminRepository(),
      notificationRepository: NotificationRepository(),
      verrouRepository: VerrouRepository(),
    ),
  );
}

class ParquetApp extends StatelessWidget {
  const ParquetApp({
    super.key,
    required this.authRepository,
    required this.partnerRepository,
    required this.eventRepository,
    required this.adminRepository,
    required this.notificationRepository,
    required this.verrouRepository,
  });

  /// Injectés pour que les tests passent de faux repositories.
  final AuthRepository authRepository;
  final PartnerRepository partnerRepository;
  final EventRepository eventRepository;
  final AdminRepository adminRepository;
  final NotificationRepository notificationRepository;
  final VerrouRepository verrouRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: adminRepository, // lu par l'écran de suivi d'un événement (ReponsesCubit)
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(authRepository, notificationRepository)..demarrer()),
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
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              // Compte bureau : toute l'app (onglets et écrans ouverts) passe sous le verrou biométrique (F17).
              builder: (context, child) => switch (auth) {
                AuthConnecte(:final session) when session.estAdmin => EcranVerrou(child: child!),
                _ => child!,
              },
              home: switch (auth) {
                AuthInconnu() => const LancementPage(),
                AuthVisiteur() => const OngletsPage(),
                AuthConnecte(:final session) => OngletsPage(session: session),
              },
            );
            // Cubits des comptes connectés : créés à la connexion, fermés à la déconnexion,
            // donc jamais les données d'un autre compte. Au-dessus du Navigator pour les listes et les détails.
            return switch (auth) {
              AuthConnecte(:final session) => MultiBlocProvider(
                key: ValueKey(session.uid),
                providers: [
                  BlocProvider(create: (_) => EventsCubit(eventRepository, notificationRepository)..charger()),
                  if (session.estAdmin) ...[
                    BlocProvider(create: (_) => AdminCubit(adminRepository)..charger()),
                    BlocProvider(create: (_) => VerrouCubit(verrouRepository)..demarrer(), lazy: false),
                  ],
                  if (!session.estAdmin)
                    BlocProvider(create: (_) => ProfileCubit(partnerRepository, session.uid)..charger()),
                ],
                child: app,
              ),
              _ => app,
            };
          },
        ),
      ),
    );
  }
}
