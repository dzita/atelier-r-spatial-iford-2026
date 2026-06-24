# `cmr_sante/` — Établissements de santé du Cameroun (OSM)

Données utilisées par J6 (Statistiques spatiales et analyse).

## Fichiers

| Fichier | Origine | Description |
|---|---|---|
| `00_telecharger_osm_sante.R` | Script de l'atelier | Télécharge depuis OpenStreetMap les facilités de santé du Cameroun via le package `osmdata` (requête Overpass). À exécuter UNE SEULE FOIS sur la machine de l'animateur. |
| `etablissements_sante_osm.csv` | Sortie du script | Listing des facilités avec coordonnées GPS, catégorie (Hôpital / Centre-Clinique / Pharmacie / Autre), et une estimation indicative de consultations mensuelles (simulée à partir de la catégorie, OSM ne renseignant pas cette information). |

## Reproduire

Pré-requis :

```r
install.packages(c("osmdata", "sf", "dplyr", "readr"))
```

Puis depuis la racine du projet RStudio :

```r
source("pedagogie/_commons/data/cmr_sante/00_telecharger_osm_sante.R")
```

Temps d'exécution : 30 à 90 secondes selon la charge des serveurs Overpass.

## Licence

OpenStreetMap est sous **ODbL 1.0** (Open Data Commons Open Database License).

> © OpenStreetMap contributors. Data is available under the Open Database License.
> Cartography licensed as CC BY-SA. <https://www.openstreetmap.org/copyright>

Tout usage public des données dérivées doit créditer OpenStreetMap.

## Limites

OSM est une base **contribuée volontairement**. La couverture des facilités de santé varie :

- **Très bonne** pour les hôpitaux de district et les pharmacies des grandes villes (Douala, Yaoundé).
- **Moyenne** pour les centres de santé en zone urbaine secondaire.
- **Partielle** pour les dispensaires ruraux, en particulier dans l'Extrême-Nord et l'Est.

Pour une analyse opérationnelle (planification sectorielle), croiser avec le **DHIS2 Cameroun** ou la base BUCREP de la santé. Pour la pédagogie, OSM est largement suffisant.

## Pour le runtime WebR

Le CSV est servi via `/_commons/data/cmr_sante/etablissements_sante_osm.csv` une fois le site déployé. Les participants sans R local peuvent l'utiliser directement dans leur navigateur :

```r
download.file("/_commons/data/cmr_sante/etablissements_sante_osm.csv",
              "etablissements.csv", mode = "wb")
etabs <- read.csv("etablissements.csv")
```
