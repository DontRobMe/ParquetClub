import 'package:flutter/material.dart';

class EtatContenu extends StatelessWidget {
  const EtatContenu({super.key, required this.icone, required this.titre, this.message, this.action});

  final IconData icone;
  final String titre;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, valeur, child) => Opacity(
        opacity: valeur,
        child: Transform.translate(offset: Offset(0, 6 * (1 - valeur)), child: child),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(icone, color: scheme.onPrimaryContainer, size: 28),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(titre, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                ),
                if (message != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    message!,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 16), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un seul reflet animé pour la zone en attente, avec une version statique si le mouvement est réduit.
class SqueletteListe extends StatefulWidget {
  const SqueletteListe({super.key, required this.libelle, this.avecVisuel = false, this.lignes = 3});

  final String libelle;
  final bool avecVisuel;
  final int lignes;

  @override
  State<SqueletteListe> createState() => _SqueletteListeState();
}

class _SqueletteListeState extends State<SqueletteListe> with SingleTickerProviderStateMixin {
  late final _reflet = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled && !MediaQuery.disableAnimationsOf(context)) {
      if (!_reflet.isAnimating) _reflet.repeat();
    } else {
      _reflet.reset();
    }
  }

  @override
  void dispose() {
    _reflet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bloc(double hauteur) => Container(
      width: double.infinity,
      height: hauteur,
      decoration: BoxDecoration(color: scheme.outline, borderRadius: BorderRadius.circular(10)),
    );
    return Semantics(
      liveRegion: true,
      label: widget.libelle,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _reflet,
          builder: (context, child) {
            final position = -1.8 + _reflet.value * 3.6;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment(position - 0.8, -0.4),
                end: Alignment(position + 0.8, 0.4),
                colors: [scheme.outline, scheme.surface, scheme.outline],
              ).createShader(rect),
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.avecVisuel) ...[bloc(188), const SizedBox(height: 16)],
              for (var i = 0; i < widget.lignes; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: bloc(64),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
