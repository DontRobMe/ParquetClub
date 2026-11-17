import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/events/data/event.dart';
import 'package:parquet/features/events/logic/events_cubit.dart';
import 'package:parquet/features/events/logic/events_state.dart';

import '../../fake_event_repository.dart';

Future<void> laisserPasser() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeEventRepository repository;
  late EventsCubit cubit;

  setUp(() {
    repository = FakeEventRepository();
    cubit = EventsCubit(repository)..charger(); // Arrange
  });

  tearDown(() => cubit.close());

  test('démarre en chargement', () {
    expect(cubit.state, isA<EventsLoading>());
  });

  test('affiche les événements à venir', () async {
    repository.envoyer([soiree, afterwork]); // Act
    await laisserPasser();
    expect((cubit.state as EventsSuccess).evenements, [soiree, afterwork]); // Assert
  });

  test('aucun événement donne l\'état vide', () async {
    repository.envoyer([]);
    await laisserPasser();
    expect(cubit.state, isA<EventsEmpty>());
  });

  test('une erreur Firestore donne l\'état erreur', () async {
    repository.evenements.addError(Exception('permission-denied'));
    await laisserPasser();
    expect(cubit.state, isA<EventsError>());
  });

  test('« Je viens » hors ligne : affiché tout de suite en attente, puis confirmé', () async {
    repository.envoyer([soiree]);
    await laisserPasser();

    final envoi = cubit.repondre('loge', vient: true, nbPersonnes: 2);
    await laisserPasser();
    var reponse = (cubit.state as EventsSuccess).reponses['loge']!;
    expect(reponse.vient, isTrue);
    expect(reponse.nbPersonnes, 2);
    expect(reponse.enAttente, isTrue);

    repository.confirmerServeur();
    await envoi;
    await laisserPasser();
    reponse = (cubit.state as EventsSuccess).reponses['loge']!;
    expect(reponse.enAttente, isFalse);
  });

  test('« Je ne viens pas » enregistre zéro personne', () async {
    repository.envoyer([soiree]);
    await laisserPasser();
    cubit.repondre('loge', vient: false, nbPersonnes: 3);
    expect(repository.appels.single.nbPersonnes, 0);
  });

  test('un événement qui disparaît de la liste perd sa réponse', () async {
    repository.envoyer([soiree]);
    await laisserPasser();
    cubit.repondre('loge', vient: true, nbPersonnes: 1);
    await laisserPasser();
    repository.envoyer([afterwork]);
    await laisserPasser();
    expect((cubit.state as EventsSuccess).reponses, isEmpty);
    expect(cubit.evenement('loge'), isNull);
  });

  test("bureau : changer la date passe l'événement à « modifié »", () async {
    final nouveau = Event(id: soiree.id, titre: soiree.titre, date: soiree.date.add(const Duration(days: 1)));
    await cubit.enregistrer(nouveau, ancien: soiree);
    expect(repository.enregistres.single.statut, EventStatut.modifie);
  });

  test('bureau : changer la description seule garde le statut', () async {
    final nouveau = Event(
      id: soiree.id,
      titre: soiree.titre,
      date: soiree.date,
      lieu: soiree.lieu,
      description: 'Tenue correcte',
    );
    await cubit.enregistrer(nouveau, ancien: soiree);
    expect(repository.enregistres.single.statut, EventStatut.prevu);
  });
}
