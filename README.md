# Atelier IFORD × GDSG 2026 — Données spatiales dans R

Matériel pédagogique de l'atelier régional **« Données spatiales, analyse et manipulation dans R »**, organisé par :

- l'**Institut de Formation et de Recherche Démographiques (IFORD)** — Yaoundé, Cameroun.
- le **Geospatial Data Science Group (GDSG)** de l'IFORD.

**Dates :** 27 juillet – 7 août 2026 · **Lieu :** Yaoundé · **Niveau :** débutant en R et SIG · **Public :** statisticiens, démographes, techniciens d'INS / BUCREP / ministères / ONG d'Afrique francophone et anglophone.

## Statut

L'atelier compte **onze journées, J01 à J11**. Le matériel est complet :
document formateur, trois scripts dérivés, runtime WebR, support de
présentation, packages et inventaire des données pour chacune.

| Journée | Document | Scripts | Runtime WebR |
|---|:-:|:-:|:-:|
| J01 · Fondations | ✅ | ✅ | ✅ |
| J02 · Penser l'espace | ✅ | ✅ | ✅ |
| J03 · Univers vectoriel | ✅ | ✅ | ✅ |
| J04 · La Terre en pixels | ✅ | ✅ | ✅ |
| J05 · Des enquêtes à la carte | ✅ | ✅ | ✅ |
| J06 · L'art de la cartographie | ✅ | ✅ | ✅ |
| J07 · Statistiques spatiales | ✅ | ✅ | ✅ |
| J08 · Population haute résolution | ✅ | ✅ | ✅ |
| J09 · Télédétection et inondations | ✅ | ✅ | ✅ |
| J10 · Politiques publiques | ✅ | ✅ | ✅ |
| J11 · Pérenniser et transmettre | ✅ | ✅ | ✅ |

Chaque dossier-jour porte un fichier `_A_FAIRE_J0X.md` : la liste des points de
contrôle à passer au rendu — hypothèses sur le contenu réel des données,
compteurs à relire, tolérances à valider. C'est la procédure de recette du
matériel, pas un inventaire de manques.

🌐 **Site WebR** : <https://dzita.github.io/atelier-r-spatial-iford-2026/>

## Programme — 11 jours

| Jour | Date 2026 | Dossier | Module | Outils clés |
|---|---|---|---|---|
| **J01** | lun. 27 juil. | `J01_fondations` | Fondations R & RStudio | base R, `tibble`, `dplyr` |
| **J02** | mar. 28 juil. | `J02_penser_espace` | Penser l'espace | `sf`, CRS, premières cartes |
| **J03** | mer. 29 juil. | `J03_univers_vectoriel` | L'univers vectoriel | `sf`, jointures attributaires et spatiales |
| **J04** | jeu. 30 juil. | `J04_terre_en_pixels` | La Terre en pixels | `terra`, Sentinel-2, NDMI |
| **J05** | ven. 31 juil. | `J05_enquetes_carte` | Des enquêtes à la carte | `haven`, `survey`, pondération, ECAM5 + EDS |
| **J06** | sam. 1ᵉʳ août | `J06_art_cartographie` | L'art de la cartographie | `tmap` v4, discrétisation, palettes |
| **J07** | lun. 3 août | `J07_statistiques_spatiales` | Statistiques spatiales | `spdep`, Moran, LISA, Gi\*, `spatstat` |
| **J08** | mar. 4 août | `J08_population_haute_resolution` | Population en haute résolution | WorldPop 100 m, GHS-POP, `exactextractr` |
| **J09** | mer. 5 août | `J09_teledetection` | Télédétection et inondations | GHS-BUILT, Copernicus EMSR772 Yagoua, Open Buildings |
| **J10** | jeu. 6 août | `J10_politiques_publiques` | Politiques publiques | ACLED, ERA5, Fay-Herriot (`sae`) |
| **J11** | ven. 7 août | `J11_perenniser_transmettre` | Pérenniser et transmettre | Quarto, Git, reproductibilité |

Dimanche 2 août : repos.

## Démarrage rapide

### Pour parcourir le matériel dans le navigateur

Aucune installation nécessaire — ouvrir le site live ci-dessus. WebR charge R et les packages dans la page (~30 s au premier accès, en cache ensuite).

### Pour utiliser le matériel en local (formateurs / collègues GDSG / participants après l'atelier)

```bash
git clone https://github.com/dzita/atelier-r-spatial-iford-2026.git
cd atelier-r-spatial-iford-2026
```

Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans **RStudio**. Le répertoire de
travail est alors la racine du projet, ce que supposent les scripts ci-dessous.

#### Étape 1 — répartir les données. **Ne pas la sauter.**

Les données vivent en **un seul exemplaire** dans `pedagogie/all_data/`. Les
dossiers `datasets/` des onze journées sont **vides après un clone** : ils ne
sont pas versionnés, ils sont reconstruits.

```r
source("outils/distribuer_donnees.R")
```

Le script balaie les onze dossiers-jours, lit dans chaque `.qmd` les littéraux
`"datasets/<fichier>"`, va chercher le fichier correspondant dans `all_data/` et
le copie — avec, pour un shapefile, tout son cortège `.shx .dbf .prj .cpg`.

**Lisez son bilan.** Il annonce le nombre de journées détectées (11 attendues),
les fichiers copiés, ceux qui sont **introuvables dans le magasin**, ceux dont
la copie a échoué, et les journées sans aucune référence. Sans ce compte rendu,
une donnée manquante ne se verrait qu'au milieu d'un rendu, plusieurs sections
plus loin.

Sont attendus en « introuvables » et ne sont pas des anomalies :
`FIES_Cameroun.csv` (jamais fourni, substitué par `s09q13a` d'ECAM5) et les
bandes Sentinel-2 **B03** et **B04** (jamais acquises — d'où le NDMI plutôt que
le NDVI en J04 et J07).

#### Étape 2 — les packages, journée par journée

Chaque journée déclare **exactement** ce qu'elle charge, et rien de plus :

```r
setwd("pedagogie/J08_population_haute_resolution")
source("install_packages_day.R")
```

Un script global existe aussi, `environnement_technique/install_packages.R`,
mais il installe l'union de tous les jours — plusieurs dizaines de minutes.
Préférez le script du jour.

#### Étape 3 — rendre

```bash
quarto render pedagogie/J08_population_haute_resolution/demo_formateur_J08.qmd
```

Pour le site WebR complet :

```bash
cd pedagogie
quarto render
```

Le site sert des **extraits légers** depuis `pedagogie/_commons/data/`. S'ils
manquent, produisez-les une fois — ce sont eux, et non les données lourdes, que
les cellules WebR lisent dans le navigateur :

```r
for (j in c("J03","J05","J06","J07","J08","J09","J10","J11"))
  source(sprintf("pedagogie/_commons/data/%s_extraits/00_extraire_%s.R", j, j))
```

### Les outils du dépôt

| Script | Rôle | Quand |
|---|---|---|
| `outils/distribuer_donnees.R` | `all_data/` → les onze `datasets/` | **après chaque clone**, et après tout ajout de données |
| `outils/consolider_all_data.R` | remonte vers `all_data/` ce qui ne serait que dans une journée | après un apport manuel de données |
| `outils/installer_materiel_J08_J10.bat` | matériel source externe J08-J10 → `all_data/` | une fois, si vous disposez du dossier source |
| `outils/A_RESTAURER.md` | ce qui manque et où le retrouver | quand `distribuer_donnees.R` signale un introuvable |
| `outils/menage_poste.md` · `menage_repo.md` | commandes `del` / `ren` du matériel remplacé | ménage |

## Structure du dépôt

```
atelier-r-spatial-iford-2026/
├── README.md                              # Ce fichier
├── MANUEL_SUPPORT_TECHNIQUE.md            # Manuel formateur (architecture, données, dépannage)
├── atelier-r-spatial-iford-2026.Rproj     # Projet RStudio
├── LICENSE                                # CC BY 4.0 sur le matériel pédagogique
│
├── environnement_technique/               # Installation globale tous packages atelier
│   ├── install_packages.R
│   ├── guide_installation.md
│   ├── verification_setup.R
│   └── architecture_quarto.md
│
├── outils/                                # Scripts de gestion des données
│   ├── distribuer_donnees.R               #   all_data -> les onze datasets/
│   ├── consolider_all_data.R              #   l'inverse, pour un apport manuel
│   ├── installer_materiel_J08_J10.bat     #   matériel source externe -> all_data
│   ├── A_RESTAURER.md · menage_*.md       #   ce qui manque, et le ménage
│   └── emprise_sentinel_2026-06-26.geojson
│
└── pedagogie/                             # Cœur pédagogique (projet Quarto)
    ├── _quarto.yml                        # Config site + navbar (11 entrées)
    ├── INDEX.md                           # Accueil du site
    ├── _extensions/r-wasm/live/           # Extension WebR, vendorisée
    ├── _commons/
    │   ├── data/                          #   Extraits légers servis à WebR
    │   │   └── J0X_extraits/              #     un 00_extraire_J0X.R par jour
    │   ├── helpers/ · styles/ · img/
    │
    ├── all_data/                          # MAGASIN CENTRAL — un exemplaire de
    │                                      # chaque donnée. Versionné.
    │
    └── J01_fondations/ … J11_perenniser_transmettre/
        ├── README.md                      #   synthèse de la journée
        ├── demo_formateur_J0X.qmd         #   SOURCE UNIQUE (§1.5)
        ├── runtime.qmd                    #   WebR navigateur
        ├── slides.qmd                     #   support revealjs
        ├── install_packages_day.R         #   packages du jour, alignés
        ├── _A_FAIRE_J0X.md                #   à vérifier au premier rendu
        ├── scripts/                       #   dérivés du .qmd, jamais écrits à la main
        │   ├── script_formateur_J0X.R
        │   ├── script_etudiant_J0X.R              (trame à trous)
        │   └── script_etudiant_J0X_corrige.R
        ├── datasets/                      #   NON VERSIONNÉ — reconstruit
        │   └── LISEZMOI.md                #     inventaire et pièges du jour
        └── outputs/                       #   NON VERSIONNÉ — régénéré
```

### Où vivent les données

**`pedagogie/all_data/`** est le magasin central : **un seul exemplaire** de
chaque fichier, et c'est lui qui est versionné.

Les `datasets/` des journées sont **dérivés** — reconstruits par
`outils/distribuer_donnees.R`, jamais commités. Les versionner reviendrait à
stocker sept fois `DS.geojson` et trois fois `gadm41_CMR.gpkg`.

Le `.qmd` de chaque journée est la **source unique** (§1.5) : les trois scripts
de `scripts/` en sont dérivés mécaniquement et ne se corrigent jamais à la main.

Convention de nommage : numérotation **sur deux chiffres partout**, `J01` à
`J11`. Trois systèmes concurrents ont coexisté dans ce dépôt — `JX` à un
chiffre, `jour_0X` décalé d'une unité, et la numérotation actuelle. Si vous
croisez un `J8` ou un `jour_07`, c'est un reste à corriger.

## Manuel technique

Le fichier **`MANUEL_SUPPORT_TECHNIQUE.md`** à la racine est destiné au support technique pendant les sessions. Il couvre :

- Architecture du dépôt et flux de rendu Quarto / WebR.
- Stack technique requise (R 4.4+, Quarto 1.4+, Git, TinyTeX).
- **Fonctionnement WebR détaillé** (mécanique `webr.resources`, limites connues).
- **Fiche détaillée par dataset** (17 sources documentées : GADM, WorldPop, GHS-POP, DHS, SRTM, OSM, ACLED, ERA5, GHSL Built-Up, EMSR772, Open Buildings, etc.) avec origine, URL, taille, licence, emplacement local, helper R, jour qui l'utilise.
- Procédures d'installation participant.
- Déploiement GitHub Pages.
- **Troubleshooting des 11 pannes déjà rencontrées** pendant la construction (XHR Invalid URL, `Edge 0 is degenerate`, terra non utilisable WebR 0.6, etc.).
- FAQ pédagogique par jour.
- Procédures d'urgence pendant l'atelier (wifi en panne, poste cassé, etc.).
- Maintenance post-atelier.

À garder ouvert pendant l'animation.

## Données

Le détail dataset par dataset est dans **`MANUEL_SUPPORT_TECHNIQUE.md` section 4**. Chaque jour a aussi sa section « Données utilisées » dans son `pedagogie/JXX_*/README.md` (embarqué WebR vs à télécharger manuellement).

Règles d'or :

- **`pedagogie/all_data/`** — le magasin central, versionné. Un exemplaire de
  chaque donnée : rasters WorldPop et GHS, tuiles GHS-BUILT, shapefiles GADM,
  produits Copernicus EMSR772, CSV WorldPop, données béninoises du J10.
- **`pedagogie/J*/datasets/`** — dérivés, **non versionnés**. Reconstruits par
  `outils/distribuer_donnees.R` après chaque clone.
- **`pedagogie/_commons/data/`** — extraits légers servis au navigateur par
  WebR, versionnés. Produits par les `00_extraire_J0X.R`, qui font en amont le
  calcul lourd (`terra`, `exactextractr`, `survey`, `spdep`) que WebR ne sait
  pas faire.
- **Absences connues et assumées** : `FIES_Cameroun.csv` n'a jamais existé —
  remplacé par `s09q13a` d'ECAM5, qui est une question unique de satisfaction
  et **non** l'échelle FAO à huit items ; la différence est écrite dans les
  documents concernés. Les bandes Sentinel-2 **B03** et **B04** n'ont jamais
  été acquises, d'où le NDMI plutôt que le NDVI.
- **Données d'enquête** : le dépôt contient des microdonnées DHS
  (`CMHR71FL.SAV`, `CMIR71FL.SAV`, `CMBR71FL.SAV`) et les positions GPS des 430
  grappes (`CMGE71FL.*`), plus les enquêtes nationales `ecam5.dta` et
  `eesi3.dta`. **La licence du DHS Program interdit la redistribution** :
  vérifier que le dépôt *et* la branche `gh-pages` sont privés avant toute
  publication. Un dépôt privé ne garantit pas une page privée.
- **Chiffres à ne pas citer** : `ecam5.dta` est un extrait de formation, non
  représentatif à l'intérieur des régions. Le taux national calculé colle à
  l'INS (38,6 % contre 37,7 %) mais l'Est ressort à 7,5 % contre 41,5 %
  publié. Les journées concernées en font un exercice et interdisent
  explicitement de citer les taux régionaux.

## Équipe

**Lead Coordinator GDSG** : Pr Mathias Kuépié (études socioéconomiques et géospatial)
**Co-Lead GDSG** : Pr Franklin Bouba Djourdebbé (études de population)
**Co-formateurs GDSG** :
- Edith Darin — Senior Researcher, ex-WorldPop/Oxford (conception J7, J8, J10 + référente bottom-up)
- Jean Saturnin Alogo Samba — Statistician + GIS (architecture J4, J5, J6)
- Marcial Teda Soh Fossi — Junior Demographer-Statistician
- **Ramesesse Dzita** — Junior Demographer-Statistician + IT Specialist (animation unique, lead IT/infrastructure, intégration finale du matériel)

Crédits détaillés par jour dans chaque `pedagogie/JXX_*/README.md` (section Crédits).

## Licence

- **Code R, scripts, slides, documents pédagogiques** : Creative Commons Attribution 4.0 International (**CC BY 4.0**). Voir `LICENSE`. Utilisation libre avec attribution `IFORD × GDSG 2026 · Ramesesse Dzita`.
- **Datasets externes** : licences d'origine respectées (GADM libre académique, WorldPop CC-BY 4.0, GHSL CC-BY 4.0, OSM ODbL, DHS Program inscription requise, ACLED Terms of Use). Détails dans le `MANUEL_SUPPORT_TECHNIQUE.md`.

## Contribuer

Pour signaler un bug ou proposer une amélioration : ouvrir une **issue** sur GitHub ou une **pull request**.

Pour suivre l'évolution post-atelier (community GDSG, slack des anciens, sessions mensuelles) : contacter ramondzita@gmail.com.

## Contact

**Ramesesse Dzita** · `ramondzita@gmail.com` · Geospatial Data Science Group, IFORD.
