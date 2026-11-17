import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/partners/data/partner_repository.dart';
import 'features/partners/logic/partners_cubit.dart';
import 'features/partners/ui/annuaire_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Après `flutterfire configure` : ajouter `options: DefaultFirebaseOptions.currentPlatform`.
  await Firebase.initializeApp();
  runApp(ParquetApp(partnerRepository: PartnerRepository()));
}

class ParquetApp extends StatelessWidget {
  const ParquetApp({super.key, required this.partnerRepository});

  /// Injecté pour que les tests passent un faux repository.
  final PartnerRepository partnerRepository;

  @override
  Widget build(BuildContext context) {
    // Le Cubit de l'annuaire est au-dessus du Navigator : la liste et la fiche détail partagent le même état.
    return BlocProvider(
      create: (_) => PartnersCubit(partnerRepository)..charger(),
      child: MaterialApp(
        title: 'Parquet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AnnuairePage(),
      ),
    );
  }
}
