# Atelier IFORD × GDSG 2026 — Données spatiales dans R

Site pédagogique de l'atelier régional **« Données spatiales, analyse et manipulation dans R »**, organisé par l'**IFORD** (Yaoundé) avec le **Geospatial Data Science Group (GDSG)**.

**27 juillet – 7 août 2026 · 11 journées (J01 à J11) · Niveau débutant en R et SIG.**

> ## 📁 Archive de l'édition 2026
>
> Ce site documente **l'édition de l'atelier tenue du 27 juillet au 7 août 2026
> à Yaoundé**. Il n'est pas un cours en ligne permanent : les dates, les
> référents et le matériel valent pour cette édition-là. Les pages restent
> publiées pour que les participants et les institutions partenaires (INS,
> BUCREP) puissent y revenir, et pour qu'une édition ultérieure reparte d'une
> base connue. Toute réutilisation doit citer l'édition et son millésime.

## État d'avancement (au 1ᵉʳ septembre 2026)

Le matériel n'est **pas encore intégralement livré**, contrairement à ce
qu'annonçait la version précédente de cette page. État réel, repris de
`../REPRISE_J06_J11.md` §1 :

| Journée | État du matériel | Ce qui manque |
|---|---|---|
| **J01** | terminé, rendu sans erreur | ni glossaire ni récapitulatif de fonctions |
| **J02** | terminé, rendu sans erreur | — (chunk non fermé corrigé le 31/08/2026) |
| **J03** | terminé, rendu sans erreur | `install_packages_day.R` absent — seule journée dans ce cas |
| **J04** | terminé, rendu et affichage vérifié | pas de section « prolongements » |
| **J05** | reconstruit (≈2 300 lignes), **non rendu** | `runtime.qmd` à reprendre ; revue des slides jamais faite |
| **J06** | **non commencé** | tout ; démo jamais rendue |
| **J07** | **non commencé** | tout ; démo jamais rendue ; fichiers internes encore en `J7`, pas `J07` |
| **J08** | réécrit le 31/08/2026, **non rendu** | exécution complète, voir `J08_population_haute_resolution/_A_FAIRE_J08.md` |
| **J09** | réécrit le 31/08/2026, **non rendu** | exécution complète, voir `J09_teledetection/_A_FAIRE_J09.md` |
| **J10** | réécrit le 31/08/2026, **non rendu** | exécution complète, voir `J10_politiques_publiques/_A_FAIRE_J10.md` |
| **J11** | **non commencé** | tout ; démo jamais rendue |

**Aucune journée n'a encore été animée avec le nouveau matériel.** Les quatre
premières journées rendent à zéro erreur ; les sept autres n'ont pas été
exécutées de bout en bout. Plusieurs jeux de données attendus sont par ailleurs
absents du poste : la liste de restauration est dans `../outils/A_RESTAURER.md`,
et le détail dans `../REPRISE_J06_J11.md` §3.

Exécution dans le navigateur via **WebR** — aucune installation requise pour la
lecture.

## Calendrier et accès direct

| Date | Journée | Thème | Runtime navigateur (WebR) |
|---|---|---|---|
| Lundi 27 juillet 2026 | **J01** | Fondations R & RStudio | [Lancer J01](J01_fondations/runtime.qmd) |
| Mardi 28 juillet 2026 | **J02** | Penser l'espace | [Lancer J02](J02_penser_espace/runtime.qmd) |
| Mercredi 29 juillet 2026 | **J03** | L'univers vectoriel | [Lancer J03](J03_univers_vectoriel/runtime.qmd) |
| Jeudi 30 juillet 2026 | **J04** | La Terre en pixels | [Lancer J04](J04_terre_en_pixels/runtime.qmd) |
| Vendredi 31 juillet 2026 | **J05** | Des enquêtes à la carte | [Lancer J05](J05_enquetes_carte/runtime.qmd) |
| Samedi 1ᵉʳ août 2026 | **J06** | L'art de la cartographie | [Lancer J06](J06_art_cartographie/runtime.qmd) |
| Lundi 3 août 2026 | **J07** | Statistiques spatiales | [Lancer J07](J07_statistiques_spatiales/runtime.qmd) |
| Mardi 4 août 2026 | **J08** | Population en haute résolution | [Lancer J08](J08_population_haute_resolution/runtime.qmd) |
| Mercredi 5 août 2026 | **J09** | Télédétection et inondations | [Lancer J09](J09_teledetection/runtime.qmd) |
| Jeudi 6 août 2026 | **J10** | Politiques publiques | [Lancer J10](J10_politiques_publiques/runtime.qmd) |
| Vendredi 7 août 2026 | **J11** | Pérenniser et transmettre | [Lancer J11](J11_perenniser_transmettre/runtime.qmd) |

> Dimanche 2 août : repos.

## Ce que contient un dossier de journée

Convention réelle, vérifiée sur les dossiers J01, J07, J08 et J09 :

| Fichier | Rôle | Pour qui |
|---|---|---|
| `README.md` | synthèse de la journée : question, modules, données, pièges | tout le monde |
| `demo_formateur_J0X.qmd` | **source unique** de la journée — code, sorties et prose | RStudio desktop |
| `script_formateur_J0X.R` | miroir exécutable du `.qmd` : même code, même ordre | formateur en salle |
| `script_etudiant_J0X.R` | trame à trous (`>>> A COMPLETER`) | participants |
| `script_etudiant_J0X_corrige.R` | corrigé, distribué en fin de journée | participants |
| `runtime.qmd` | version WebR exécutable dans le navigateur | participants en autonomie |
| `slides.qmd` et/ou `*.pptx` | support de projection | formateur |
| `install_packages_day.R` | packages spécifiques du jour, à lancer une fois | formateur, première install |
| `datasets/` + `datasets/LISEZMOI.md` | données du jour, à plat, avec leur inventaire vérifié | tout le monde |
| `outputs/` | sorties du code, préfixées `J0X_` — créé à l'exécution | — |

**Deux irrégularités subsistent** et sont documentées ici plutôt que masquées :

- **Emplacement des trois scripts.** J08, J09 et J10 les rangent dans
  `scripts/` (avec, sur le poste actuel, un doublon resté à la racine du
  dossier). Les autres journées les gardent à la racine du dossier-jour.
  L'harmonisation vers `scripts/` reste à faire.
- **Numérotation à un chiffre.** J06 et J07 nomment encore leurs fichiers
  `…_J6.R`, `…_J7.qmd`. Le passage en `J06` / `J07` est prévu (voir
  `../REPRISE_J06_J11.md` §3).

Les anciens noms `demo.qmd`, `demo.R`, `exercice.qmd` et `corrige.qmd` — encore
cités par quelques `README.md` de journée — appartiennent au **matériel v1** et
ne sont plus la convention.

Le `runtime.qmd` n'exécute pas tout : il couvre les opérations **portables sur
WebR** (`sf`, `dplyr`, `ggplot2`). Les opérations non portables (`terra`,
`srvyr`, `spdep`, `sae`, `exactextractr`, `ncdf4`, `mapedit`, `tmap`
interactif) sont présentées en blocs de lecture seule, avec leur code commenté,
et renvoient au `demo_formateur_J0X.qmd` pour exécution sous RStudio desktop.

## Programme détaillé

**J01 — Changer d'outil sans changer de métier : les fondations.** Amener un
public habitué à STATA et SPSS au même point de départ. Installation guidée de
R et RStudio, tableau de correspondance permanent avec les logiciels d'origine,
premiers scripts et organisation en projet, objets de base et valeurs
manquantes, import de données d'enquêtes nationales réelles (`.dta`, `.SAV`,
tableur) et premiers réflexes d'exploration.

**J02 — Penser l'espace : où, et pourquoi là ?** Poser le vocabulaire de
l'information géographique avant toute ligne de code : points, lignes,
polygones, grilles ; opérations fondamentales ; formats de fichiers,
géodatabases multi-couches et systèmes de coordonnées. La journée porte aussi
le **module IA** (méthode en 4 temps, règles d'or) qui sert toute la formation.
Les participants ne codent pas encore, hormis une première carte du Cameroun en
fin de journée.

**J03 — L'univers vectoriel : points, lignes et territoires.** Reprendre en
pratique ce qui a été vu conceptuellement au J02, selon le plan lecture →
transformation → sauvegarde. Lire tous les formats géographiques, inspecter
systématiquement une couche avant analyse, vérifier et transformer le CRS avant
tout calcul métrique, puis enchaîner superficies, tampons, intersections et
jointures spatiales sur les données du Cameroun.

**J04 — La Terre en pixels : les données d'observation continue.** Anatomie
d'une donnée en grille (étendue, résolution, bandes), lecture d'imagerie
Sentinel-2 réelle et d'un modèle de terrain, géotraitements essentiels
(découper, masquer, rééchantillonner, agréger), croisement grilles × territoires
et statistiques zonales. Le **NDVI n'est pas calculé** : la bande B04 manque et
le dériver de l'image `True_color` produirait une carte fausse — le **NDMI**
(B08/B11) est l'indice réellement calculé, et le point devient un enseignement.

**J05 — Des enquêtes à la carte : relier données et territoires.** Une enquête
produit des lignes, une carte demande des polygones : comment passe-t-on des
unes aux autres, et que perd-on en route ? Les deux ponts sont construits l'un
après l'autre — la jointure par clé commune, puis la jointure spatiale. Fil
conducteur : l'accès à l'eau potable croisé à la pauvreté monétaire, du national
au district sanitaire. Cinq pièges réels, qui échouent tous sans lever d'erreur.

**J06 — Faire parler les cartes : l'art de la visualisation.** Grammaire des
cartes thématiques (choroplèthes, cartes à points, facettes), principes de bonne
conception et pièges classiques, cartes officielles sur données réelles
(population et densité par département), palettes, classes, légendes et
habillage, puis cartes interactives et petits tableaux de bord. La journée
insiste sur la citation de la source **sur chaque carte**.

**J07 — Le hasard a-t-il une géographie ? Statistiques spatiales.** Partir de
problèmes concrets — épidémies, incidence du paludisme, accès aux services —
pour introduire chaque outil : motifs spatiaux (aléatoire, agrégé, régulier),
autocorrélation spatiale, détection des concentrations locales (points chauds et
froids), estimation de densité. La pratique porte sur la répartition des
établissements de santé et des écoles, et la journée se ferme sur ce que ces
méthodes disent — et ne disent pas — aux décideurs.

**J08 — Compter chaque habitant : la grille de population.** Combien
d'habitants dans ce quartier, ce bassin versant, ce rayon de 5 km ? Aucun
recensement ne répond : les unités administratives ne coïncident pas avec le
territoire d'une décision. Neuf modules mènent du tableau COD-PS à la grille
WorldPop 100 m, puis à l'agrégation par région, à la densité, au MAUP, et à la
confrontation WorldPop / GHS-POP / COD-PS. Deux avertissements structurent la
journée : **une grille est un modèle, pas une observation**, et **deux grilles
sérieuses ne donnent pas le même chiffre**.

**J09 — Voir le territoire depuis l'espace : télédétection, bâti et
inondations.** Que peut-on mesurer d'un territoire où l'on ne peut pas aller ?
Trois réponses de valeur inégale : un rayonnement, un produit dérivé fabriqué
par d'autres (GHS-BUILT, Open Buildings, Copernicus EMS), et le croisement de
deux produits indépendants. Cas réel : l'activation EMSR772 sur Yagoua 2024, le
comptage des bâtiments exposés et la longueur de route inondée. Les chiffres
portent sur une **fenêtre de 5 × 5 km**, pas sur l'inondation entière.

**J10 — Les données spatiales au service des politiques publiques.** Comment une
donnée spatiale devient-elle un argument recevable devant un décideur ? Trois
familles de données : événementielle (ACLED), réanalyse climatique (ERA5), et
enquête modélisée en petits domaines (Fay-Herriot). **La partie III change de
pays** — Bénin, EHCVM 2018-2019 — parce que l'extrait camerounais disponible
n'est pas représentatif au niveau infrarégional ; ce qu'on y apprend est la
méthode, pas le diagnostic. La journée lance aussi les mini-projets.

**J11 — Pérenniser et transmettre.** Analyses reproductibles (un même document →
rapport Word, page web, présentation), travail collaboratif versionné,
présentation de la plateforme de formation en ligne et de sa construction sous
WebR, restitution des mini-projets, principes FAIR et métadonnées géospatiales,
feuille de route INS/BUCREP, clôture officielle et remise des attestations.

## Ressources transverses

### Au niveau racine du dépôt

- [`../README.md`](../README.md) — présentation générale, démarrage rapide, équipe, licence.
- [`../MANUEL_SUPPORT_TECHNIQUE.md`](../MANUEL_SUPPORT_TECHNIQUE.md) — manuel formateur (architecture, datasets fichés, troubleshooting WebR, FAQ pédagogique par jour, urgences atelier).
- [`../REPRISE_J06_J11.md`](../REPRISE_J06_J11.md) — état d'avancement de référence, fiches de données vérifiées, décisions à ne pas rouvrir.
- [`../REGLES_MATERIEL_ATELIER.md`](../REGLES_MATERIEL_ATELIER.md) — règles de travail sur le matériel.
- [`../environnement_technique/install_packages.R`](../environnement_technique/install_packages.R) — installation globale de tous les packages atelier.
- [`../environnement_technique/guide_installation.md`](../environnement_technique/guide_installation.md) — guide pas-à-pas pour participants.

### Dans `pedagogie/`

- `_commons/helpers/fetch_data.R` — résolution de chemins datasets (locale + fallback).
- `_commons/helpers/citations.bib` — bibliographie commune.
- `_commons/styles/` — feuilles de style SCSS revealjs + reference-doc PPTX IFORD.
- `_commons/img/logo-iford.jpg` — logo institutionnel.
- `_commons/data/` — extraits légers servis par les runtimes WebR.
- `_extensions/r-wasm/live/` — extension Quarto pour le runtime WebR.
- `_SITE_ETAT.md` — journal des corrections du squelette du site.

## Modes d'accès

### Vous lisez en ligne (le plus simple)

Tout ce site est servi sur GitHub Pages : <https://dzita.github.io/atelier-r-spatial-iford-2026/>. Aucune installation. WebR charge R et les packages dans la page (~30 s la première fois, en cache ensuite).

### Vous voulez faire tourner les démos complètes en local

```bash
git clone https://github.com/dzita/atelier-r-spatial-iford-2026.git
cd atelier-r-spatial-iford-2026
```

Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans **RStudio**, puis dans la console :

```r
source("environnement_technique/install_packages.R")
source("outils/distribuer_donnees.R")   # remplit les datasets/ de chaque jour
```

Puis ouvrir le `demo_formateur_J0X.qmd` d'un jour et cliquer **Render**. Chaque
dossier-jour porte en plus son propre `install_packages_day.R`, à lancer une
fois.

### Vous êtes formateur en salle

Ouvrir `script_formateur_J0X.R` du jour dans RStudio et exécuter section par
section sur projecteur (miroir exact du `demo_formateur_J0X.qmd`, sans la prose
narrative).

## Crédits

- **Lead Coordinator GDSG** : Pr Mathias Kuépié
- **Co-Lead GDSG** : Pr Franklin Bouba Djourdebbé
- **Référente J09, J10, J11** : Edith Darin (Senior Researcher, ex-WorldPop/Oxford, référente bottom-up).
- **Référent J05, J06, J07, J08** : Jean Saturnin Alogo Samba.
- **Référents transverses** : M. Teda et R. Dzita · **Support** : R. Elandi.
- **Animation, lead IT/infrastructure et intégration finale** : Ramesesse Dzita — <ramondzita@gmail.com>.

(Répartition reprise des lignes « Référents » des `README.md` de chaque journée.)

Le programme officiel IFORD est dans le document de cadrage `Atelier sur l'analyse des données Géospatiales avec R.docx`. Ce site en est l'**implémentation technique reproductible**.
