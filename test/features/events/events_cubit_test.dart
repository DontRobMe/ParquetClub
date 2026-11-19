import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/events/data/event.dart';
import 'package:parquet/features/events/logic/events_cubit.dart';
import 'package:parquet/features/events/logic/events_state.dart';

import '../../fake_event_repository.dart';
import '../../fake_notification_repository.dart';

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

  test("conserve la couverture en Firestore et lit les événements sans photo", () async {
    final photo = Uint8List.fromList([1, 2, 3]);
    final event = Event(id: soiree.id, titre: soiree.titre, date: soiree.date, photo: photo);
    await cubit.enregistrer(event);
    final donnees = repository.enregistres.single.toMap();
    expect(Event.fromMap(event.id, donnees).photo, photo);
    donnees.remove('photo');
    expect(Event.fromMap(event.id, donnees).photo, isNull);
  });

  test("l'émargement ouvre le jour même et seul un présent peut noter après l'heure", () {
    final evenement = Event(id: 'test', titre: 'Match', date: DateTime(2026, 11, 19, 19));
    const present = EventResponse(vient: false, nbPersonnes: 0, presence: true);
    const absent = EventResponse(vient: true, nbPersonnes: 2, presence: false);
    final avant = DateTime(2026, 11, 19, 8);
    expect(evenement.emargementOuvert(DateTime(2026, 11, 18, 23, 59)), isFalse);
    expect(evenement.emargementOuvert(avant), isTrue);
    expect(present.peutNoter(evenement, avant), isFalse);
    expect(present.peutNoter(evenement, evenement.date), isTrue);
    expect(absent.peutNoter(evenement, evenement.date), isFalse);
  });

  group('rappel 2 jours avant (F16)', () {
    late FakeNotificationRepository notifications;
    late EventsCubit avecRappels;

    setUp(() async {
      notifications = FakeNotificationRepository();
      avecRappels = EventsCubit(repository, notifications)..charger();
      repository.envoyer([soiree, afterwork]);
      await laisserPasser();
    });

    tearDown(() => avecRappels.close());

    test('« Je viens » programme le rappel', () async {
      avecRappels.repondre('loge', vient: true, nbPersonnes: 2);
      await laisserPasser();
      expect(notifications.rappels.keys, ['loge']);
    });

    test("changer d'avis retire le rappel", () async {
      avecRappels.repondre('loge', vient: true, nbPersonnes: 2);
      await laisserPasser();
      avecRappels.repondre('loge', vient: false);
      await laisserPasser();
      expect(notifications.rappels, isEmpty);
    });

    test('un événement annulé perd son rappel', () async {
      avecRappels.repondre('loge', vient: true, nbPersonnes: 1);
      await laisserPasser();
      repository.envoyer([
        Event(id: soiree.id, titre: soiree.titre, date: soiree.date, statut: EventStatut.annule),
        afterwork,
      ]);
      await laisserPasser();
      expect(notifications.rappels, isEmpty);
    });

    test('une nouvelle date reprogramme le rappel', () async {
      avecRappels.repondre('loge', vient: true, nbPersonnes: 1);
      await laisserPasser();
      final reportee = soiree.date.add(const Duration(days: 7));
      repository.envoyer([
        Event(id: soiree.id, titre: soiree.titre, date: reportee, statut: EventStatut.modifie),
        afterwork,
      ]);
      await laisserPasser();
      expect(notifications.rappels['loge']!.date, reportee);
    });
  });

  test('rappel : autorisation demandée seulement si elle manque', () async {
    final notifications = FakeNotificationRepository(aDemander: true);
    final avecRappels = EventsCubit(repository, notifications);
    expect(await avecRappels.rappelsADemander(), isTrue);
    await avecRappels.autoriserRappels();
    expect(notifications.demandes, 1);
    await avecRappels.close();
  });
}
