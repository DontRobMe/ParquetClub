# Questions probables du jury

Réponses courtes que chaque membre du groupe doit savoir donner, avec le cours d'origine. Elles complètent le [cahier des charges](cahier-des-charges.pdf) et collent au code du dépôt.

| Question | Réponse attendue | Cours |
| --- | --- | --- |
| Pourquoi Flutter et pas du natif ? | Un seul code pour iOS et Android, petite équipe, besoin natif faible et couvert par des plugins | 4 |
| Pourquoi Cubit et pas BLoC ? | Cubit = on appelle une méthode, BLoC = on envoie un événement. Nos actions sont simples : les événements n'apporteraient que du code en plus. Même paquet, même testabilité | 4 |
| Pourquoi pas setState partout ? | La liste des événements est partagée par plusieurs écrans : un état partagé doit sortir du widget. setState reste utilisé pour l'état purement local | 1, 4 |
| Quel est le lien entre Cubit et MVVM ? | Le Cubit joue le rôle du ViewModel : il expose l'état, la vue l'affiche, le repository fournit les données | 1, 2, 4 |
| Que sont les 4 états d'un écran ? | Chargement, erreur, vide, succès, modélisés par une sealed class et traités par un switch exhaustif | 1, 4 |
| Pourquoi l'annuaire est-il public ? | Le but du club est la visibilité des partenaires. La fiche ne contient que des infos pro, choisies par le partenaire ; le numéro perso est dans un document séparé | 6 |
| Que se passe-t-il au gymnase sans réseau ? | Firestore lit son cache local, l'écran affiche les dernières données ; une réponse « Je viens » est mise en file et envoyée au retour du réseau | 1 |
| Que se passe-t-il si l'app est tuée pendant la saisie d'une fiche ? | L'état vit dans le Cubit et les données enregistrées dans Firestore ; seule une saisie non validée est perdue | 1 |
| Différence notification locale / push ? | Locale : déclenchée par l'app (rappel). Push : envoyée par un serveur via FCM, arrive même app fermée. Sur le forfait Spark, seul le rappel local existe | 3 |
| Pourquoi le rappel est-il local ? | Il ne dépend que du téléphone : il part même sans réseau, et sans serveur | 3 |
| Pourquoi pas de notification push ? | Forfait Spark gratuit, sans carte : pas de Cloud Functions pour envoyer un push. Il demanderait le forfait Blaze (0 € au volume d'un club, mais une carte). Les événements restent visibles en temps réel dans l'app, et le rappel J-2 est local | 3, 6 |
| Comment protégez-vous le compte admin ? | Droits vérifiés côté serveur (règles Firestore, rôle dans un profil que personne ne modifie soi-même), biométrie à l'ouverture, journal des actions | 6 |
| Comment bloquer un compte volé ? | Le bureau le désactive : le champ disabled fait refuser toute lecture et écriture par les règles, sans attendre, et l'app déconnecte le compte | 6 |
| Que vaut une biométrie réussie ? | Seulement un « oui » local : elle verrouille l'app, elle ne remplace pas les règles serveur | 6 |
| Où stockez-vous un secret sur le téléphone ? | Keystore / Keychain via flutter\_secure\_storage, jamais shared\_preferences | 6 |
| La clé Firebase dans l'app, c'est un secret en dur ? | Non : elle identifie le projet, elle ne donne aucun droit. La sécurité repose sur les règles Firestore | 6 |
| Quelles permissions demandez-vous ? | Uniquement les notifications, au bon moment et avec explication ; la galerie passe par le sélecteur système | 3, 6 |
| Pourquoi seulement un logo et pas de photo ? | Une photo de personne est une donnée personnelle et demande son accord (droit à l'image). Le logo évite tout ça | 6 |
| Pourquoi pas de bandeau de consentement ? | Aucun traceur ni analytics, rien sur les visiteurs : la base légale est le contrat de partenariat | 6 |
| Comment cacher le numéro personnel ? | Document séparé, lisible seulement par son propriétaire et le bureau, car les règles Firestore filtrent par document | 6 |
| Pourquoi texte blanc sur rouge et pas noir ? | Blanc sur #E30613 = 4,9 pour 1 (conforme AA) ; noir sur rouge = 4,3 pour 1 (refusé) | 5 |
| Où sont les boutons importants ? | En bas, dans la zone du pouce ; les actions destructrices loin du pouce et confirmées | 5 |
| Comment supprimer le compte de connexion d'un partenaire sans Cloud Functions ? | Le bureau efface le profil et les données. À sa prochaine tentative de connexion, l'app ne trouve plus de profil et supprime elle-même le compte Auth (seul le compte peut se supprimer sur Spark) | 6 |
| Comment vérifiez-vous l'accessibilité ? | Un test automatique parcourt les écrans principaux en taille de texte normale et doublée : zones tactiles de 48 dp, libellés, contraste WCAG, aucun débordement | 5, 6 |
| Pourquoi deux rouges dans l'app ? | Le rouge de la charte fait 4,4 pour 1 sur le fond papier, trop peu pour du texte. Les liens, erreurs et étiquettes passent en rouge foncé #C00510 (5,9 pour 1) ; les boutons gardent #E30613 | 5 |
| Le bureau peut-il répondre à une invitation ? | Non : l'app lui montre « Voir les réponses », et les règles Firestore refusent une réponse d'un compte qui n'a pas le rôle partenaire | 6 |
