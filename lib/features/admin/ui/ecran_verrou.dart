import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../logic/verrou_cubit.dart';

/// Recouvre toute l'app du bureau tant qu'elle est verrouillée. L'app reste en place dessous :
/// on retrouve l'écran où l'on était après le déverrouillage.
class EcranVerrou extends StatefulWidget {
  const EcranVerrou({super.key, required this.child});

  final Widget child;

  @override
  State<EcranVerrou> createState() => _EcranVerrouState();
}

class _EcranVerrouState extends State<EcranVerrou> {
  late final AppLifecycleListener _cycleDeVie;

  @override
  void initState() {
    super.initState();
    // Cycle de vie (cours 1) : passage en arrière-plan = verrouillage au retour.
    _cycleDeVie = AppLifecycleListener(onHide: () => context.read<VerrouCubit>().verrouiller());
  }

  @override
  void dispose() {
    _cycleDeVie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerrouCubit, VerrouState>(
      // Dès que l'écran de verrou apparaît, la fenêtre biométrique du système s'ouvre.
      listenWhen: (avant, apres) => !avant.verrouille && apres.verrouille,
      listener: (context, _) => context.read<VerrouCubit>().deverrouiller(),
      builder: (context, state) => Stack(
        children: [
          // Caché au lecteur d'écran et aux appuis tant que c'est verrouillé.
          ExcludeSemantics(
            excluding: state.verrouille,
            child: IgnorePointer(ignoring: state.verrouille, child: widget.child),
          ),
          if (state.verrouille) const Positioned.fill(child: _Verrou()),
        ],
      ),
    );
  }
}

class _Verrou extends StatelessWidget {
  const _Verrou();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.secondary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.lock_outline, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'ESPACE BUREAU',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(color: scheme.onSecondary),
              ),
              Text(
                'Verrouillé par empreinte ou visage.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSecondary),
              ),
              const Spacer(),
              FilledButton(onPressed: context.read<VerrouCubit>().deverrouiller, child: const Text('Déverrouiller')),
            ],
          ),
        ),
      ),
    );
  }
}
