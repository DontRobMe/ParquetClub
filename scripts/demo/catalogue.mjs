const beaublanc = 'Palais des sports de Beaublanc · 23 boulevard de Beaublanc, 87100 Limoges';
const eveche = '1 place de l’Évêché, 87000 Limoges';
const jeanGagnant = '16 avenue Jean Gagnant, 87000 Limoges';
const republique = '1 place de la République, 87000 Limoges';

export const partenaires = [
  {
    nom: 'Nike', metier: 'Équipement sportif', secteur: 'Autre', ville: 'Paris', logo: 'nike.png',
    site: 'https://www.nike.com/fr/',
    description: 'Chaussures et tenues de basket, du premier entraînement au jour du match. Les gammes mêlent maintien, amorti et légèreté pour les joueurs et joueuses de tous niveaux.',
  },
  {
    nom: 'adidas', metier: 'Tenues et chaussures de sport', secteur: 'Autre', ville: 'Paris', logo: 'adidas.png',
    site: 'https://www.adidas.fr/',
    description: 'Collections pour l’entraînement, la compétition et les déplacements. Chaussures, textiles techniques et accessoires complètent l’équipement des équipes.',
  },
  {
    nom: 'PUMA', metier: 'Équipement et textile de sport', secteur: 'Autre', ville: 'Paris', logo: 'puma.png',
    site: 'https://eu.puma.com/fr/fr',
    description: 'Chaussures et vêtements pour les entraînements et les matchs. Les collections basket mêlent amorti, maintien et graphismes inspirés des terrains.',
  },
  {
    nom: 'Fnac', metier: 'Culture et billetterie', secteur: 'Services', ville: 'Limoges', logo: 'fnac.png',
    site: 'https://www.fnac.com/',
    description: 'Livres, musique, image et son. La billetterie permet de découvrir les concerts, spectacles et événements sportifs à l’affiche.',
  },
  {
    nom: 'New Balance', metier: 'Chaussures et préparation sportive', secteur: 'Autre', ville: 'Paris', logo: 'new-balance.png',
    site: 'https://www.newbalance.fr/',
    description: 'Chaussures et vêtements pour le sport comme pour les trajets du quotidien. Les collections associent confort, maintien et technicité.',
  },
  {
    nom: 'Boulanger', metier: 'Image et matériel numérique', secteur: 'Services', ville: 'Limoges', logo: 'boulanger.png',
    site: 'https://www.boulanger.com/',
    description: 'Conseil sur les écrans, les micros et le matériel de captation qui servent lors d’une retransmission ou d’une présentation.',
  },
  {
    nom: 'Atelier Terre Claire', metier: 'Céramique et cadeaux d’entreprise', secteur: 'Artisanat',
    ville: 'Limoges', adresse: '12 rue Porte Panet',
    description: 'Un atelier de petites séries en grès et en porcelaine. Les pièces sont tournées et émaillées sur place, des tasses de réception aux trophées personnalisés.',
  },
  {
    nom: 'Maison Sésame', metier: 'Traiteur et buffets', secteur: 'Restauration', ville: 'Panazol',
    description: 'Buffets de saison pour réceptions, plateaux déjeuner et pauses gourmandes. Les menus s’adaptent au nombre d’invités et peuvent inclure des options végétariennes.',
  },
  {
    nom: 'Cadence Studio', metier: 'Photographie et vidéo', secteur: 'Services', ville: 'Limoges',
    description: 'Reportages de match, portraits d’équipe et vidéos courtes. Le studio documente les événements dans la salle, en bord de terrain et dans les coulisses.',
  },
  {
    nom: 'Café des Quais', metier: 'Torréfaction artisanale', secteur: 'Restauration', ville: 'Limoges',
    description: 'Cafés de spécialité torréfiés en petites quantités, dégustations et barista pour les accueils et matinées partenaires.',
  },
  {
    nom: 'Signal Bois', metier: 'Mobilier et signalétique', secteur: 'Artisanat', ville: 'Isle',
    description: 'Fabrication locale de mobilier mobile, de comptoirs d’accueil et de signalétique réutilisable pour les salles et événements.',
  },
  {
    nom: 'Studio Lisière', metier: 'Création graphique', secteur: 'Services', ville: 'Limoges', desactive: true,
    description: 'Identités visuelles, supports imprimés et habillages pour les manifestations associatives.',
  },
];

// Chaque réponse indique partenaire, taille du groupe (0 = refus, null = pas de RSVP), présence, note et commentaire.
export const evenements = [
  {
    id: 'lancement-saison', jour: -72, titre: 'Cocktail de lancement de saison', type: 'Soirée partenaires',
    lieu: 'Salon du club · 23 boulevard de Beaublanc, 87100 Limoges', photo: 'salle.jpg',
    description: 'Présentation du calendrier, échanges avec le staff et cocktail debout. Accueil à partir de 18 h 30, puis présentation des temps forts de la saison.',
    reponses: [
      [1, 2, true, 5, 'Le format court et les rencontres avec le staff ont très bien fonctionné.'],
      [2, 3, true, 4, 'Très bon accueil. Un badge avec le nom de chaque entreprise faciliterait les premiers échanges.'],
      [6, 1, false], [8, 2, true, 5], [9, 0],
    ],
  },
  {
    id: 'visite-atelier', jour: -49, heure: 10, titre: 'Porcelaine et savoir-faire', type: 'Visite',
    lieu: 'Quartier de la Cité',
    description: 'Visite d’atelier en petit groupe, du tournage à la cuisson. Prévoir des chaussures fermées pour la partie démonstration.',
    reponses: [[5, 2, true, 5, 'Une belle découverte, avec le temps de poser des questions.'], [7, 3, true, 4], [10, 0]],
  },
  {
    id: 'match-octobre', jour: -33, titre: 'La soirée des tribunes', type: 'Match en loge',
    lieu: beaublanc, photo: 'entrainement.jpg',
    description: 'Ouverture du salon partenaires une heure avant le coup d’envoi. Rendez-vous à l’entrée principale pour récupérer les invitations.',
    reponses: [[1, 2, true, 5, 'Super ambiance dans les tribunes.'], [2, 1, true, 4], [3, 2, false], [4, null, true, 5], [8, 0]],
  },
  {
    id: 'dejeuner-eveche', jour: -20, heure: 12, titre: 'Déjeuner du réseau', type: 'Déjeuner',
    lieu: eveche,
    description: 'Déjeuner en tables de six. Chacun présente son activité et une idée de collaboration avec le réseau du club.',
    reponses: [[2, 1, true, 4], [3, 2, true, 5, 'Le tour de table a facilité deux rendez-vous utiles.'], [7, 1, true, 4], [8, 2, true, 5], [11, 0]],
  },
  {
    id: 'brief-technique', jour: -13, titre: 'Brief technique en petit comité', type: 'Atelier',
  },
  {
    id: 'afterwork-passe', jour: -4, titre: 'Rencontres au bord du parquet', type: 'Afterwork',
    lieu: 'Salon partenaires · accès porte B',
    description: 'Un afterwork de 90 minutes avec trois tours de rencontres et une pause autour d’un buffet de saison. Tenue libre.',
    reponses: [
      [1, 2, true], [2, 1, true, 5, 'Les échanges en petits groupes étaient vraiment utiles.'],
      [3, 2, false], [4, null, true, 4, 'Bon rythme. Un plan d’accès pour les premières visites serait pratique.'],
      [7, 0], [8, 3, true, 4], [10, 1, true],
    ],
  },
  {
    id: 'jour-j', jour: 0, heure: 19, minute: 30, titre: 'Soirée partenaires à Beaublanc', type: 'Match en loge',
    photo: 'match.jpg', lieu: beaublanc,
    description: 'Accueil au salon partenaires, présentation des équipes, puis place au match depuis la tribune. Les invités récupèrent leur entrée auprès du bureau.',
    reponses: [[1, 2], [2, 1, true, 5, 'Une belle soirée avec une équipe d’accueil disponible.'], [3, 3, true], [5, 0, false], [8, 2], [10, 1]],
  },
  {
    id: 'petit-dejeuner', jour: 2, heure: 8, minute: 30, titre: 'Petit-déjeuner · idées et projets',
    type: 'Réseautage', lieu: jeanGagnant,
    description: 'Café, viennoiseries et présentations de dix minutes. Venez avec une idée de projet et repartez avec deux contacts pour la faire avancer.',
    reponses: [[2, 2], [4, 1], [8, 2], [9, 1], [10, 2], [11, 0]],
  },
  {
    id: 'entrainement-ouvert', jour: 5, titre: 'Dans les coulisses de l’entraînement', type: 'Visite',
    lieu: beaublanc, photo: 'entrainement.jpg',
    description: 'Assistez à une séance depuis les tribunes et échangez avec l’équipe technique à la fin de l’entraînement. Arrivée quinze minutes avant le début.',
  },
  {
    id: 'atelier-image', jour: 9, heure: 17, titre: 'Photographier un match', type: 'Atelier',
    lieu: 'Rendez-vous au pied des tribunes, côté table de marque',
    description: 'Un atelier pratique sur les réglages en salle, le cadrage d’une action rapide et la préparation d’un reportage de match. Apportez un appareil ou un téléphone chargé.',
    reponses: [[1, 1], [4, 2], [6, 0], [9, 2]],
  },
  {
    id: 'atelier-decale', jour: 13, titre: 'Atelier signalétique · nouvel horaire', type: 'Atelier', statut: 'modifie',
    lieu: 'Porte B, espace technique',
    description: 'L’atelier débute à 18 h. Le groupe testera les parcours d’accueil et préparera la signalétique pour la prochaine soirée.',
    reponses: [[6, 2], [7, 1], [11, 2]],
  },
  {
    id: 'tournoi-annule', jour: 17, titre: 'Tournoi interentreprises', type: 'Tournoi', statut: 'annule',
    lieu: beaublanc,
    description: 'Le tournoi est annulé. Une nouvelle date sera proposée dans l’agenda une fois le créneau confirmé.',
    reponses: [[1, 2], [2, 2], [8, 4]],
  },
  {
    id: 'reunion-bureau', jour: 23, titre: 'Point de fin de mois', type: 'Rencontre',
  },
  {
    id: 'visite-centre-ville', jour: 31, heure: 14, titre: 'Parcours partenaires en centre-ville', type: 'Visite',
    lieu: republique,
    description: 'Trois étapes à pied pour découvrir des métiers du réseau. Départ groupé, pause à mi-parcours et retour libre à partir de 16 h.',
    reponses: [[4, 2], [7, 2], [8, 1], [10, 2]],
  },
];
