# J10 — Les données spatiales au service des politiques publiques

**Atelier IFORD × GDSG 2026 · Jeudi 6 août 2026 · Yaoundé**

**Référents : E. Darin, M. Teda, R. Dzita · Support : R. Elandi**

---

> ## ⚠ Avertissement — cette journée change de pays en cours de route
>
> Les **parties I et II** (modules 1 à 4) portent sur le **Cameroun** : conflits
> armés rapportés par ACLED, température de l'air ERA5.
>
> La **partie III** (modules 5 à 9), consacrée à l'**estimation sur petits
> domaines**, porte sur le **Bénin** — enquête EHCVM 2018-2019, communes,
> grille de 3 km.
>
> **Ce n'est pas une négligence, c'est une décision de méthode.** L'estimation
> sur petits domaines exige une enquête dont on puisse calculer, domaine par
> domaine, une estimation directe **et sa variance d'échantillonnage réelle** :
> il faut simultanément les poids de sondage, l'identifiant de grappe et une
> géolocalisation. L'extrait camerounais dont l'atelier dispose (`ecam5.dta`)
> échoue au contrôle de référence imposé par la méthode : son taux de pauvreté
> national colle au chiffre publié par l'INS (38,6 % contre 37,7 %), mais **à
> l'intérieur des régions il décroche** — l'Est y ressort à 7,5 % contre 41,5 %
> publié. C'est un extrait de formation, non représentatif au niveau
> infrarégional. Un exercice d'estimation sur petits domaines construit dessus
> produirait des cartes départementales magnifiques, et des chiffres qu'il
> faudrait ensuite interdire de citer.
>
> **Ce que ce déplacement coûte, et qu'il faut dire aux participants :** le fil
> rouge camerounais de l'atelier se rompt (impossible de relier la carte
> d'insécurité alimentaire aux cartes ACLED et ERA5 du matin) ; le vocabulaire
> administratif change (communes béninoises, 77 unités) ; et **aucun chiffre de
> la partie III ne décrit le Cameroun**. Ce que l'on apprend là est la
> **méthode**, pas le diagnostic.

---

## La question de la journée

**Comment une donnée spatiale devient-elle un argument recevable devant un
décideur ?**

Trois familles de données, trois façons d'y répondre — et trois façons de se
tromper :

| Famille | Fichier | Unité d'observation | Ce qu'elle mesure vraiment |
|---|---|---|---|
| Événementiel | `acled_cameroon_export.csv` | l'**événement rapporté** | ce que des sources ont rapporté, daté et localisé |
| Réanalyse | `era5_t2m_mensuel_cameroun.nc` | la **cellule de ~31 km**, par mois | la sortie d'un modèle météorologique contraint par des observations |
| Enquête | `ehcvm2018_benin_menages.csv` | le **ménage enquêté**, dans une grappe | une déclaration de ménage, à pondérer pour parler de la population |

Aucune des trois n'est « la réalité ». Chacune est une construction dont il faut
connaître la règle de fabrication avant de la cartographier.

## Progression par module

| # | Module | Ce qu'on y fait | Données |
|---|---|---|---|
| 1 | Données événementielles | structure d'ACLED, précision géographique et temporelle, sentinelles, séries annuelles, décès | `acled_cameroon_export.csv` |
| 2 | Du point au polygone | jointure par libellé (échec provoqué), normalisation, table de correspondance, `st_within`, choroplèthe, MAUP | ACLED + `gadm41_CMR.gpkg` |
| 3 | Réanalyse climatique | NetCDF, Kelvin → Celsius, `crop` + `mask`, contrôle visuel | `era5_t2m_mensuel_cameroun.nc` |
| 4 | Extraction zonale temporelle | `exact_extract()` multicouche, série nationale, LOESS, saisonnalité | ERA5 + ADM1 |
| 5 | Une enquête ne suffit pas | plan de sondage, pondération, estimation directe, variance non estimable | `ehcvm2018_benin_menages.csv` |
| 6 | Choisir une covariable | criblage de corrélation, contrôle de colinéarité | `benin_covariables_admin2.csv` |
| 7 | Fay-Herriot | EBLUP, EQM, `gain_rmse`, **le nuage gain vs taille d'échantillon comme test du mécanisme** | idem |
| 8 | Trois cartes à échelle commune | direct, Fay-Herriot, gain — et les communes grises | `gadm_ben_communes.gpkg` |
| 9 | Précision ≠ résolution | prédiction sur grille 3 km, et l'avertissement qui doit l'accompagner | `benin_grille_3km.gpkg`, `benin_covariables_grille.csv` |
| 10 | Accessibilité aux services | isochrones 5/10/15 km, distances aux districts sanitaires — **module non exécuté**, voir ci-dessous | `DS.geojson`, `gadm41_CMR_2.shp` |

**Le module 10 est conservé mais désactivé** (`eval: false`). Ses deux fichiers
de données sont absents du poste, et le code d'origine reposait de surcroît sur
une erreur : il lisait les coordonnées des formations sanitaires dans
`CMGC72FL.csv`, un fichier qui n'en contient aucune (ce sont les 130
covariables contextuelles par grappe DHS ; les positions sont dans
`CMGE71FL.shp`). Le code réécrit est fourni, commenté, prêt à être réactivé.
Voir `_A_FAIRE_J10.md`.

## Les pièges mis en scène

Chaque module porte un piège nommé, provoqué délibérément puis corrigé devant
les participants :

1. **Un événement ACLED n'est pas un fait vérifié**, c'est un fait *rapporté*.
   La base mesure aussi l'activité des sources qui le rapportent.
2. **La jointure par libellé qui échoue en silence** (module 2). Les `admin1`
   d'ACLED sont en français non accentué (`Sud`, `Extreme-Nord`), les `NAME_1`
   de GADM en anglais (`South`, `Far North`). `left_join()` ne lève aucune
   erreur : il remplit de `NA`, que `replace_na(0)` transforme en régions
   « pacifiées ». Le module fait *tenter* la jointure, compte les dégâts, montre
   que la normalisation des chaînes ne suffit pas (c'est une différence de
   *langue*, pas d'accents), écrit une table de correspondance à la main, puis
   passe à `st_within`.
3. **Kelvin** (module 3). ERA5 est en degrés Kelvin. Une moyenne non convertie
   se repère à l'ordre de grandeur ; une **différence** non convertie, jamais.
4. **Les noms de couches d'`exact_extract()`** (module 4) : l'ordre alphabétique
   n'est pas l'ordre chronologique (`t2m_10` < `t2m_2` en tri texte).
5. **Un échantillon n'est pas la population** (module 5). Sans les poids on
   décrit l'échantillon ; sans les grappes on divise artificiellement
   l'erreur-type, donc on publie une fausse certitude.
6. **La variance non estimable** (module 5). Une commune à une seule grappe n'a
   pas de variance calculable. Elle est exclue du modèle — et **reste visible en
   gris sur la carte**, jamais à zéro, jamais effacée.
7. **Corrélation n'est pas causalité, colinéarité n'est pas information**
   (module 6). Avec 76 communes et neuf candidates, on trouvera toujours quelque
   chose de corrélé.
8. **Un gain moyen faible n'est pas un échec du modèle** (module 7) : c'est le
   signe que l'hétérogénéité réelle entre communes domine le bruit
   d'échantillonnage.
9. **Deux cartes à échelles différentes ne se comparent pas** (module 8). Les
   `limits` sont imposées.
10. **Précision n'est pas résolution** (module 9). La carte de grille est la
    plus impressionnante de la journée, et la moins mesurée : chaque cellule
    porte une valeur *prédite* par un modèle ajusté sur 76 communes.
11. **Distance euclidienne n'est pas accessibilité** (module 10), et
    **superficie couverte n'est pas population couverte**.

Deux pièges de raisonnement traversent la journée entière : le **MAUP** (aucune
maille n'est neutre ; on agrège à la maille de la décision) et l'**erreur
écologique** (une choroplèthe décrit l'agrégat, jamais les individus).

## Fichiers de ce dossier

| Fichier | Rôle |
|---|---|
| `README.md` | ce fichier |
| `demo_formateur_J10.qmd` | **la source unique** : document Quarto, tout le code et toute la prose. Les trois `.R` en dérivent |
| `install_packages_day.R` | packages du jour, à lancer **une fois** (`sae` et `survey` sont longs) |
| `datasets/` | données du jour, à plat — voir `datasets/LISEZMOI.md` |
| `datasets/LISEZMOI.md` | inventaire vérifié, unité d'observation, pièges chiffrés |
| `scripts/script_formateur_J10.R` | miroir exécutable du `.qmd` : même code, même ordre |
| `scripts/script_etudiant_J10.R` | trame à trous — 60 emplacements `>>> A COMPLETER` |
| `scripts/script_etudiant_J10_corrige.R` | corrigé complet, distribué en fin de journée |
| `jour_09_applications_sociales.pptx` | support de présentation, **français** |
| `jour_09_applications_sociales_en.pptx` | support de présentation, **anglais** |
| `jour_09_applications_sociales_fr_en.pptx` | support de présentation, **bilingue** |
| `archive_en/` | scripts anglais d'origine, **archivés** : non maintenus, non réécrits, conservés pour référence |
| `_A_FAIRE_J10.md` | ce qui reste à vérifier côté poste, et les commandes de ménage |
| `outputs/` | toutes les sorties (créé automatiquement au premier rendu) |

**Multilingue.** Seules les trois présentations `.pptx` existent en FR, EN et
bilingue. Tout le reste du matériel — `.qmd`, scripts, README, LISEZMOI — est en
**français uniquement**. Les scripts `_en.R` d'origine sont archivés dans
`archive_en\` et ne sont plus maintenus.

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier
`datasets/` (fichiers **à plat**, aucun sous-répertoire), lues en chemins
relatifs `datasets/<fichier>` par le `.qmd` et par les scripts. Les sorties vont
dans `outputs/`, préfixées `J10_`. **Une sortie n'écrit jamais dans
`datasets/`.**

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus, avec leur unité d'observation et les
sections qui les consomment, est dans `datasets/LISEZMOI.md`.

## Déroulé de la journée

*Journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00.*

**Session 1 (08h30–10h30) — Cameroun**
Modules 1 à 4 : les données événementielles (ACLED), le passage du point au
polygone et le piège de la jointure, la réanalyse climatique (ERA5) et
l'extraction zonale temporelle.

**Session 2 (11h00–13h00) — Bénin**
Modules 5 à 7 : plan de sondage et estimation directe, choix des covariables,
modèle de Fay-Herriot et test du mécanisme.

**Session 3 (14h00–16h00)**
Modules 8 et 9 : les trois cartes à échelle commune, puis précision contre
résolution. Module 10 en exposé (code de référence, non exécuté).
Séquence IA du jour : construire un argumentaire chiffré pour un décideur.

**Session 4 (16h15–17h00)**
Lancement des mini-projets : groupes, sujets, grille d'évaluation.

## Prolongements vers J11

Le J11 travaille la restitution. Les trois familles de données du jour se
prêtent à trois registres d'argumentation : l'événementiel raconte une
**dynamique**, la réanalyse installe un **contexte**, l'enquête modélisée
fournit un **ciblage**.

Trois compétences directement réutilisables dans les mini-projets :

1. la chaîne **événement → polygone → carte**, applicable à toute base
   géolocalisée (structures sanitaires, écoles, incidents, prix de marché,
   points d'eau) ;
2. la chaîne **enquête → estimation directe → modèle → carte**, ossature d'une
   carte de pauvreté, de scolarisation ou d'accès à l'eau à maille fine — trois
   ingrédients requis : les poids, les grappes, une covariable connue partout ;
3. le **vocabulaire de l'incertitude** (RMSE, EQM, intervalle, taille
   d'échantillon, commune non estimable), qui distingue une carte défendable en
   réunion d'une carte à retirer dès la première question.

Trois extensions techniques à explorer après l'atelier : les **isochrones
réels** par réseau routier (`osrm`, OpenRouteService) ; le **modèle unitaire**
(`povmap`, EBP) au lieu du modèle d'aire ; l'**autocorrélation spatiale** dans
le modèle de Fay-Herriot (SFH), pour que deux communes voisines s'informent
mutuellement.

## Une question à emporter

Toutes les cartes de cette journée ont été produites à partir de données que
quelqu'un d'autre a construites : ACLED code des dépêches, ERA5 fait tourner un
modèle, l'EHCVM interroge des ménages selon un plan. Avant de présenter l'une
de ces cartes, la question n'est jamais « est-elle jolie ? » mais **« qu'est-ce
qui a été mesuré, par qui, sur quoi, et que reste-t-il non mesuré ? »**
