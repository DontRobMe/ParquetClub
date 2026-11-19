import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LancementPage extends StatelessWidget {
  const LancementPage({super.key, this.reessayer, this.animerLogo = true});

  final VoidCallback? reessayer;
  final bool animerLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mouvementReduit = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: scheme.secondary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: mouvementReduit || !animerLogo ? Duration.zero : const Duration(milliseconds: 650),
                    curve: const Cubic(0.2, 0.8, 0.2, 1),
                    builder: (context, valeur, enfant) => Opacity(
                      opacity: valeur,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - valeur)),
                        child: Transform.rotate(
                          angle: -0.96 * (1 - valeur),
                          child: Transform.scale(scale: 0.8 + 0.2 * valeur, child: enfant),
                        ),
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                      child: const Padding(
                        padding: EdgeInsets.all(15.5),
                        child: CustomPaint(size: Size.square(44), painter: _Ballon()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PARQUET.',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onSecondary,
                      fontSize: 53,
                      height: 0.95,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text('Club partenaires', style: TextStyle(color: scheme.onSecondary)),
                  const SizedBox(height: 24),
                  if (reessayer == null)
                    SizedBox(
                      width: 154,
                      child: LinearProgressIndicator(
                        value: mouvementReduit ? 0.35 : null,
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: Color.lerp(scheme.secondary, scheme.primary, 0.28),
                        semanticsLabel: 'Chargement de Parquet',
                        semanticsValue: mouvementReduit ? 'En cours' : null,
                      ),
                    )
                  else ...[
                    Text(
                      'Parquet ne peut pas démarrer pour le moment.',
                      style: TextStyle(color: scheme.onSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: reessayer, child: const Text('Réessayer')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ballon extends CustomPainter {
  const _Ballon();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final trait = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(12, 12), 9, trait);
    canvas.drawLine(const Offset(3, 12), const Offset(21, 12), trait);
    canvas.drawLine(const Offset(12, 3), const Offset(12, 21), trait);
    final coutures = Path()
      ..moveTo(6, 5.5)
      ..cubicTo(12, 8.5, 12, 15.5, 6, 18.5)
      ..moveTo(18, 5.5)
      ..cubicTo(12, 8.5, 12, 15.5, 18, 18.5);
    canvas.drawPath(coutures, trait);
  }

  @override
  bool shouldRepaint(covariant _Ballon oldDelegate) => false;
}
