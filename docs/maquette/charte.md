# Parquet · Charte d’interface

Parquet est le nom de travail du réseau partenaires du club. Le pictogramme de ballon sert d’emblème provisoire. Les entreprises, événements et coordonnées sont des données de démonstration.

## Références et adaptation

| Référence | Principe repris dans la maquette |
| --- | --- |
| [NBA App](https://apps.apple.com/us/app/nba-live-games-scores/id484672289) · [Tap to Watch](https://www.nba.com/news/nba-digital-experiences-2026-27) | Quand un rendez-vous a la priorité, réunir le visuel, l’heure et l’action dans la même zone. L’action du club est « Répondre à l’invitation ». |
| [Formula 1 App](https://apps.apple.com/us/app/formula-1/id835022598) · [Refonte officielle](https://www.formula1.com/en/latest/article/formula-1-launches-new-website-and-personalised-mobile-app.1knZbPSCZ2tS2z6ADRn2Gs) | Reprendre les filtres courts et la mise en avant des prochains rendez-vous pour faciliter le repérage. |
| [Business Club du Paris Basketball](https://parisbasketball.com/business-club/) | Donner à la loge, à l’afterwork et aux rencontres entre entreprises des parcours explicites. |
| [Partenaires du Limoges CSP](https://www.limogescsp.com/index.php/liste-des-partenaires.html) | Donner aux entreprises un espace identifiable, puis ajouter la recherche par activité et ville pour faciliter les mises en relation. |

## Identité et composants

| Élément | Spécification |
| --- | --- |
| Marque | Rouge #E30613 pour l’action principale. Noir #000000 pour les barres et le lancement. Blanc #FFFFFF pour les textes sur rouge ou noir et les cartes. |
| Surfaces et textes | Fond #F6F4F0, encre #111112, texte secondaire #626064, contours #E6E3DF. Statuts accompagnés d’un libellé. |
| Typographie | Barlow Condensed 700 pour les titres et chiffres. DM Sans 400–700 pour les contenus et contrôles. Intégrer les deux familles au bundle Flutter. |
| Rythme | Marges courantes 18–22 dp. Espacements 8, 12, 16 et 24 dp. Rayon 8–12 dp. Cible tactile de 48 dp ou plus pour les actions d’application. |
| Photo | Visuel éditorial de terrain en ouverture. Dégradé noir sous les titres blancs. Cadrage serré sur mobile. Les fiches d’entreprise utilisent uniquement un logo ou des initiales. |
| Navigation | Barre noire, icône et libellé visibles. Indication de l’onglet actif par la couleur de l’icône et la graisse du texte. Une action principale pleine largeur dans le détail d’invitation et les formulaires. |
| Formulaires | Libellé persistant, un champ par ligne, claviers email/téléphone/URL. Message de visibilité à côté du champ personnel. Confirmation des actions sensibles. |

## Mouvement

- Lancement de la démo sur fond noir. Le ballon rouge entre par translation courte, rotation de 55° et fondu en 650 ms. Écran affiché pendant une seconde dans la démo. Dans Flutter, terminer dès que la session est résolue et utiliser les états de données si une liste attend encore.
- Écrans et dialogues sur 220–240 ms. Fondu et translation de 7 dp, avec décélération. Garder la barre d’onglets en place.
- Chargement de liste avec trois lignes squelettes. Définir un état d’erreur récupérable et un état vide distinct.
- En mouvement réduit, masquer les transitions et rendre le squelette statique. Côté Flutter, lire `MediaQuery.disableAnimationsOf(context)` et adapter aussi les transitions de route.
- Lors d’un RSVP sans connexion, afficher le nombre choisi et « En attente de synchronisation ». Confirmer par un message de statut lorsque la réponse quitte la file.

## Écrans et contrôle de la maquette

| Parcours | Écrans et actions |
| --- | --- |
| Visiteur | Accueil public, annuaire et filtres, fiche, liens de contact, confidentialité, connexion et récupération. |
| Partenaire | Agenda, invitation, présence avec nombre, absence, notifications, profil, édition de la vitrine et rappel. |
| Bureau | Tableau de bord, invitations, gestion des comptes, création/modification/annulation d’événement, liste des réponses, journal et aperçu du contrôle biométrique. |
| États | Lancement, chargement, erreur et relance, absence de données, hors connexion et RSVP en attente. |

Sur téléphone, ouvrir les contrôles avec l’icône de réglages en haut. Sur ordinateur, les rôles sont à gauche et le réseau simulé à droite. Essayer « Partenaire → Répondre → Hors connexion → Je viens → En ligne → Bureau → Gérer les événements ». Les changements sont locaux au navigateur. Firebase, les e-mails, les notifications système et la biométrie font partie de la transposition native. Effacer le stockage local du navigateur pour reprendre les données initiales.

## Visuel sportif

`assets/terrain.jpg` est une image originale produite avec ImageGen intégré. Prompt utilisé :

> Wide 3:2 cinematic editorial photograph for a premium French basketball business club mobile app, no text or graphics. From courtside at hardwood floor height, one anonymous adult male player in a plain red basketball jersey jumping toward the hoop at far right, silhouette back view, upper right action; black arena, dark stands, atmospheric haze, overhead powerful white arena floodlights, subtle deep red rim lighting, authentic basketball arena, warm parquet reflected lighting, high contrast sports campaign photography shot on 35mm. Leave the left third and lower left visually dark with negative space for white typography. Rich shadow details, restrained color, no audience portraits, no brand logo, no words, no watermarks, no collage.
