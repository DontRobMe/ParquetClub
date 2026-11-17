import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/main.dart';

void main() {
  testWidgets("l'écran de lancement affiche le nom de l'app", (tester) async {
    await tester.pumpWidget(const ParquetApp()); // Arrange + Act
    expect(find.text('PARQUET.'), findsOneWidget); // Assert
  });
}
