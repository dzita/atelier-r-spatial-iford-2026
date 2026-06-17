# Architecture technique de la stack Quarto — Atelier IFORD × GDSG 2026

> Référence technique pour maintenir et étendre le matériel pédagogique. Décrit comment Quarto, WebR, GitHub Actions et GitHub Pages s'articulent, et documente les ajustements non évidents que nous avons dû faire pour que tout marche.

## 1. Vue d'ensemble

Le matériel pédagogique de l'atelier se décompose en deux flux de publication parallèles :

```
                              ┌──────────────────────────────────┐
                              │  Sources : pedagogie/JXX_…/      │
                              │  - demo.qmd + demo.R             │
                              │  - slides.qmd                    │
                              │  - runtime.qmd                   │
                              │  - exercice.qmd + corrige.qmd    │
                              └────────────────┬─────────────────┘
                                               │
                  ┌────────────────────────────┴────────────────────────────┐
                  │                                                         │
                  ▼                                                         ▼
   ┌──────────────────────────────┐                  ┌────────────────────────────────────┐
   │  Rendu desktop (animateur)    │                  │  Site web + runtime WebR (public)   │
   │  - quarto render              │                  │  - quarto render → _site/           │
   │  - Local R + RStudio          │                  │  - GitHub Action ci/cd              │
   │  - Sorties HTML + PDF + PNG   │                  │  - Pages : gh-pages branch          │
   │                               │                  │  - URL : dzita.github.io/atelier-…  │
   └──────────────────────────────┘                  └────────────────────────────────────┘
```

Côté **desktop** : Quarto rend les `.qmd` localement, R/knitr exécute les chunks, les sorties HTML/PDF sont distribuées aux participants équipés.

Côté **web** : la même base source produit un site Quarto avec navigation, un runtime WebR exécutant R **côté navigateur** sans serveur R, et un déploiement automatique via GitHub Pages pour les participants non équipés.

## 2. Le projet Quarto à `pedagogie/`

### 2.1 `_quarto.yml` racine du projet

Le fichier `pedagogie/_quarto.yml` déclare un projet Quarto de type `website` dédié à la stack runtime WebR. Sa liste `render:` est volontairement **restreinte** aux fichiers `runtime.qmd` et aux deux pages d'index :

```yaml
project:
  type: website
  output-dir: _site
  render:
    - "INDEX.md"
    - "README.md"
    - "J*/runtime.qmd"
  resources:
    - "_commons/img/**"
    - "_commons/data/**"
```

Les fichiers `demo.qmd`, `exercice.qmd`, `corrige.qmd`, `slides.qmd` ne sont **pas** dans la liste `render:` — ils sont rendus à la demande (Render bouton dans RStudio ou `quarto render <fichier>` en ligne de commande) avec leur propre YAML. C'est volontaire : ils n'ont pas besoin de partager la navbar du site runtime.

Le bloc `resources:` est crucial. Sans lui, Quarto ne copie pas les fichiers de `_commons/img/` ni `_commons/data/` dans `_site/`, et les URL absolues du type `/_commons/data/gadm41_CMR_1.json` retournent 404.

### 2.2 Format `live-html`

Pour les runtime, le format est `live-html` (fourni par l'extension `quarto-live` de r-wasm) :

```yaml
format:
  live-html:
    toc: true
    toc-depth: 2
    toc-location: left
    theme:
      - cosmo
      - _commons/styles/runtime_quartolive.scss
    code-tools: true
    code-link: true

filters:
  - live

webr:
  packages:
    - tibble
    - dplyr
    - sf
    - ggplot2
  render-df: gt-interactive
  cell-options:
    autorun: false
    fig-width: 7
    fig-height: 5
```

`filters: - live` enclenche le post-processing Pandoc qui transforme les cellules `{webr}` en widgets interactifs. La liste `webr.packages:` instruit WebR de pré-installer ces paquets **côté navigateur** au chargement de la page.

### 2.3 Liste de packages WebR : règle de minimalisme

WebR pré-installe chaque package listé dans `webr.packages:` au chargement de la page. Chaque package supplémentaire alourdit le téléchargement et peut bloquer le chargement si :

- le package n'existe pas sur <https://repo.r-wasm.org/> (cas connu : `tmap` n'y est pas, ses dépendances sont trop nombreuses),
- le package a des dépendances système non portables en WebAssembly.

**Règle** : ne lister que ce qui est strictement utilisé par au moins un `runtime.qmd`. Si J5 introduit `srvyr` et J6 `spdep`, ne les ajouter qu'à ce moment-là. Si un runtime spécifique a besoin d'un package non-global, on peut le déclarer au niveau document via :

```yaml
---
webr:
  packages:
    - lwgeom
---
```

Quarto fusionne la liste document avec la liste projet.

### 2.4 Navbar, logo, filigrane

La navbar IFORD est définie dans `_quarto.yml` :

```yaml
website:
  navbar:
    background: "#0F4C81"
    logo: /_commons/img/logo-iford.jpg
    logo-href: INDEX.md
    logo-alt: "IFORD"
    left:
      - href: INDEX.md
        text: "Accueil"
      - text: "Modules"
        menu:
          - href: J01_intro_R_pensee_spatiale/runtime.qmd
            text: "J1 · Intro R + pensée spatiale"
```

Note : `logo:` utilise un chemin **absolu** (`/_commons/img/...`) parce que Quarto strip parfois le préfixe `_commons/` quand il résout une URL relative à la position du HTML rendu. L'absolu garantit la résolution correcte à toutes les profondeurs (`_site/INDEX.html`, `_site/J01_…/runtime.html`, etc.).

Le filigrane est dans `_commons/styles/runtime_quartolive.scss` :

```scss
body::before {
  content: "";
  position: fixed;
  bottom: 24px;
  right: 24px;
  width: 140px;
  height: 140px;
  background-image: url("/_commons/img/logo-iford.jpg");
  background-size: contain;
  background-repeat: no-repeat;
  opacity: 0.12;
  pointer-events: none;
  z-index: -1;
}
```

`position: fixed` garde le filigrane à sa place pendant le scroll. `pointer-events: none` permet aux clics de traverser le filigrane (sinon il bloque les cellules WebR situées en bas-droite). `z-index: -1` garantit qu'il reste sous tout autre contenu.

## 3. Les six types de `.qmd` et leurs formats

| Fichier | Format YAML | Engine | Sortie typique |
|---|---|---|---|
| `slides.qmd` | `revealjs` avec thème `default + slides_revealjs.scss` | knitr | HTML interactif revealjs |
| `demo.qmd` | `html` + `pdf` | knitr | HTML statique + PDF optionnel |
| `runtime.qmd` | hérité du projet (`live-html`) | knitr | HTML avec cellules WebR |
| `exercice.qmd` | `html` + `pdf` | knitr | HTML statique + PDF |
| `corrige.qmd` | `html` (avec `bibliography`) | knitr | HTML statique |

Les chunks dans `demo.qmd`, `exercice.qmd`, `corrige.qmd` sont des `{r}` classiques : R s'exécute au render, les sorties sont gravées dans le HTML.

Les chunks dans `runtime.qmd` sont des `{webr}` : ils ne s'exécutent **pas** au render — le filtre Lua `live` les transforme en widgets HTML, R les exécute dans le navigateur du participant au moment où il clique sur **Run code**.

### 3.1 Configuration commune `toc-location: left`

Par convention, tous les `format: html` et le `format: live-html` du projet utilisent `toc-location: left` pour avoir la table des matières à gauche plutôt qu'à droite (défaut Quarto). Cette préférence doit être posée dans chaque YAML standalone (`demo.qmd`, `exercice.qmd`, `corrige.qmd`) car le `_quarto.yml` projet ne s'applique qu'aux fichiers de sa liste `render:`.

## 4. Runtime local (`quarto preview`)

### 4.1 Préparation initiale

Avant le premier `quarto preview`, depuis le dossier `pedagogie/` :

```powershell
cd "C:\Dev\GitHub\atelier-r-spatial-iford-2026\pedagogie"
quarto add r-wasm/quarto-live
```

Cette commande télécharge et installe l'extension `quarto-live` dans `pedagogie/_extensions/r-wasm/live/`. Le dossier `_extensions/` doit être **commité** dans le repo — il fait partie de la configuration projet et la CI GitHub Actions en a besoin pour rendre le site.

### 4.2 Lancer le serveur de preview

```powershell
cd "C:\Dev\GitHub\atelier-r-spatial-iford-2026\pedagogie"
quarto preview
```

Quarto démarre un serveur local (port aléatoire dans la plage 4000-9000), ouvre automatiquement le navigateur sur l'INDEX, et **watche** les fichiers source. Toute modification déclenche un re-render incrémental + un reload navigateur via WebSocket.

Pour rendre un fichier standalone (non couvert par le projet, comme `slides.qmd`) :

```powershell
quarto render J01_intro_R_pensee_spatiale/slides.qmd
```

### 4.3 L'engine `knitr` est obligatoire pour les `{webr}` cells

Le YAML de chaque `runtime.qmd` doit explicitement déclarer :

```yaml
---
engine: knitr
---
```

Sans cette ligne, Quarto cherche un moteur par défaut et tombe sur jupyter, qui exige Python + `yaml` package, et qui plante avec un message du type :

```
ModuleNotFoundError: No module named 'yaml'
```

Avec `engine: knitr`, R prend en charge le parsing du document. knitr ne **comprend** pas le type de chunk `{webr}` et émet un warning :

```
Warning: Unknown language engine 'webr' (must be registered via knit_engines$set()).
```

Ce warning est **cosmétique** : son comportement par défaut consiste à ré-émettre le bloc en sortie avec une classe `webr cell-code`, ce qui est exactement ce dont le filtre Lua `live` a besoin pour le transformer en widget interactif. **Ne pas tenter de faire taire ce warning** en enregistrant un engine no-op (`knitr::knit_engines$set(webr = function(options) "")`) — cela supprimerait les cellules de l'output au lieu de les laisser passer au filtre Lua.

### 4.4 Diagnostic d'erreur Quarto

Si `quarto preview` ou `quarto render` plante avec un message succinct du type « Error encountered when rendering files », relancer en mode debug :

```powershell
quarto render <fichier.qmd> --log-level debug 2>&1 | Tee-Object -FilePath quarto_debug.log
```

Le fichier `quarto_debug.log` contient la trace complète, y compris les chemins absolus utilisés par Quarto pour résoudre les ressources et les bibliothèques R appelées.

## 5. Runtime en ligne (GitHub Actions + Pages)

### 5.1 Workflow `publish-runtime.yml`

Le déploiement automatique est dans `.github/workflows/publish-runtime.yml`. Déclenché à chaque push sur `main` (et manuellement via workflow_dispatch), il :

1. Checkout du repo,
2. Setup de Quarto (version épinglée à 1.9.38 pour éviter qu'une montée de version côté runner casse un build local-OK),
3. Setup de R (paquet `r-lib/actions/setup-r@v2`),
4. Installation de `knitr` et `rmarkdown` côté runner (knitr est nécessaire au parse même si aucun chunk `{r}` n'est exécuté),
5. `quarto render` du projet `pedagogie/`,
6. Déploiement du dossier `_site/` sur la branche `gh-pages` via l'action `peaceiris/actions-gh-pages@v4`.

### 5.2 Pourquoi `peaceiris/actions-gh-pages` et pas `quarto-dev/quarto-actions/publish`

`quarto-dev/quarto-actions/publish` exige que la branche `gh-pages` **existe déjà** sur le remote. Au premier déploiement elle n'existe pas, et l'action plante avec :

```
ERROR: Unable to publish to GitHub Pages (the remote origin does not have a branch named "gh-pages".
Use first `quarto publish gh-pages` locally to initialize the remote repository for publishing.)
```

`peaceiris/actions-gh-pages@v4` **crée la branche** si elle n'existe pas, et la met à jour si elle existe. Plus robuste, plus simple, indépendant du shell de l'animateur (pas besoin de bootstrap manuel depuis PowerShell).

L'option `force_orphan: true` garde la branche `gh-pages` légère : seul le dernier build est gardé, sans historique. C'est volontaire — la branche ne sert que de pipeline de publication, pas d'archive.

### 5.3 Configuration GitHub Pages côté repo

Une fois le premier workflow réussi (branche `gh-pages` créée), enregistrer dans **Settings → Pages** :

- Source : « Deploy from a branch »
- Branch : `gh-pages` · Folder : `/ (root)`
- Save

GitHub Pages construit son edge cache (~30 à 90 secondes) puis l'URL publique devient `https://<user>.github.io/<repo>/`. Pour notre projet : <https://dzita.github.io/atelier-r-spatial-iford-2026/>.

### 5.4 Servir les datasets via `resources:`

Les fichiers GADM sont copiés dans `pedagogie/_commons/data/` puis déclarés dans `_quarto.yml` :

```yaml
project:
  resources:
    - "_commons/data/**"
```

Au render, Quarto copie tel quel le contenu vers `_site/_commons/data/`. Le déploiement gh-pages les expose à <https://dzita.github.io/atelier-r-spatial-iford-2026/_commons/data/gadm41_CMR_1.json>.

Côté cellule WebR, on les charge avec un chemin **absolu** (commence par `/`) qui marche en local preview et en production :

```r
download.file("/_commons/data/gadm41_CMR_1.json", "adm1.json", mode = "wb")
adm1 <- sf::read_sf("adm1.json")
```

Le `/` initial signifie « racine du site web courant ». En `quarto preview` local, cela résout vers <http://localhost:NNNN/_commons/data/...>. En production, vers le sous-chemin de Pages.

**Limite de taille** : la branche `gh-pages` est servie par GitHub Pages avec une limite douce de ~1 Go au total et 100 Mo par fichier. Les datasets WorldPop GeoTIFF (~150 Mo) sont à exclure de cette voie et à laisser côté desktop seulement.

## 6. Gotchas connus

### 6.1 OneDrive et Git ne s'aiment pas

Le dossier `C:\Users\<user>\Documents\` est **synchronisé par OneDrive sur une installation Windows par défaut**. Y placer un dépôt Git provoque :

- des verrous de synchronisation persistants sur `.git/index.lock` (git commit refuse de démarrer),
- des fichiers en mode placeholder qui apparaissent tronqués aux outils CLI (mais sont intacts en lecture par les applications Windows natives),
- des troncations en plein milieu de fichiers lors de gros writes, particulièrement sur des `.qmd` longs ou des `.json` denses.

**Convention adoptée** : tout dépôt Git versionné de l'atelier vit dans `C:\Dev\GitHub\` (hors de tout dossier synchronisé). Les documents non versionnés (plaquette, présentations, notes) restent dans `OneDrive\`. Voir `guide_installation.md` §9.1.

### 6.2 `sf_version()` n'existe pas, utiliser `packageVersion("sf")`

Le package `sf` n'expose pas de fonction `sf_version()` (contrairement à `terra::terraVersion()`). Utiliser :

```r
packageVersion("sf")
sf::sf_extSoftVersion()  # versions de GDAL, GEOS, PROJ
```

### 6.3 `here::here()` peut être trompé par `pedagogie/_quarto.yml`

`here::here()` détecte la racine du projet en remontant jusqu'à trouver un sentinel (`.Rproj`, `.here`, etc.). Mais il s'arrête aussi sur un `_quarto.yml`, et notre projet en a un dans `pedagogie/`. Conséquence : un `here::here("datasets", "...")` appelé depuis un `runtime.qmd` retourne `pedagogie/datasets/...` au lieu de `<racine>/datasets/...`.

Solution adoptée dans `_commons/helpers/fetch_data.R` :

```r
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
.DATASETS_ROOT <- file.path(.PROJECT_ROOT, "datasets")
```

`rprojroot::find_root()` cherche un sentinel **précis** (notre `.Rproj` racine) et ignore les `_quarto.yml` intermédiaires.

### 6.4 Le commit `_extensions/`

Le dossier `pedagogie/_extensions/r-wasm/live/` créé par `quarto add r-wasm/quarto-live` doit être commité. Sans lui, la CI GitHub Action ne sait pas que `filter: live` existe et plante avec :

```
ERROR: Unable to read the extension 'live'.
```

Le `.gitignore` du projet n'exclut **pas** `_extensions/`.

### 6.5 `quarto preview` : recharger après modification

Le serveur de preview watche les `.qmd` et les ressources statiques (SCSS, images). Pour les changements de YAML projet (`_quarto.yml`), un redémarrage du serveur est parfois nécessaire (Ctrl+C puis relancer).

Pour invalider le cache navigateur de WebR (notamment quand on change la liste `webr.packages:`) : Ctrl+Shift+R (hard reload) ou un onglet privé.

### 6.6 Bibliographie : clés exactement référencées

Chaque citation `@nomcle` dans un `.qmd` doit avoir une entrée correspondante dans `_commons/helpers/citations.bib`. Une faute de frappe (par exemple `@darin_leasure_2023_bottomup` au lieu de `@darin2023bottomup`) génère un warning Quarto et un `[?]` dans la sortie HTML. Vérifier avant chaque push.

## 7. Stratégie données et runtime WebR

| Volume du fichier | Stratégie |
|---|---|
| < 5 Mo | Copier dans `pedagogie/_commons/data/`, fetch via `download.file("/_commons/data/...")` dans la cellule. |
| 5 à 20 Mo | Pareil mais avec un avertissement explicite à l'utilisateur sur le temps de chargement la première fois. |
| 20 à 50 Mo | Cas limite. Préférer une version simplifiée (`rmapshaper::ms_simplify`) avant copie. |
| > 50 Mo | Ne **pas** mettre dans le runtime WebR. Laisser uniquement dans la version desktop, documenter le chemin de téléchargement manuel dans `fetch_data.R`. |

GADM Cameroun JSON est suffisamment léger pour entrer dans le runtime :

| Niveau | Taille |
|---|---|
| ADM0 (frontière nationale) | ~600 Ko |
| ADM1 (10 régions) | ~190 Ko |
| ADM2 (départements) | ~410 Ko |
| ADM3 (arrondissements) | ~685 Ko |

Pour WorldPop, GHSL, Meta HRSL : 30 à 150 Mo chacun, **desktop uniquement**.

## 8. Mise à jour de la liste de packages WebR

Quand un nouveau module introduit un package qu'on veut tester côté runtime :

1. Vérifier sa disponibilité sur <https://repo.r-wasm.org/> (parcourir le listing).
2. Ajouter à `_quarto.yml` sous `webr.packages:`.
3. `quarto preview` localement, hard reload navigateur, tester que le téléchargement aboutit en moins de 60 secondes sur une connexion moyenne.
4. Si le téléchargement bloque indéfiniment, retirer le package de la liste. Chercher un substitut (souvent `ggplot2 + geom_sf` remplace `tmap`, `dplyr` remplace `data.table`).

## 9. Mise à jour de la version Quarto

Quarto évolue vite (~1 release majeure tous les 2-3 mois). Pour mettre à jour :

1. Tester localement avec la nouvelle version (`quarto --version`).
2. Si OK, mettre à jour le pin dans `.github/workflows/publish-runtime.yml` :

   ```yaml
   - name: Setup Quarto
     uses: quarto-dev/quarto-actions/setup@v2
     with:
       version: "X.Y.Z"
   ```

3. Push, vérifier que la CI passe.

L'épinglage explicite évite qu'une montée silencieuse côté runner casse un build local-OK pendant que tu es en salle.

## 10. Diagnostic rapide « ça marche en local, ça plante en CI »

| Symptôme dans les logs Actions | Cause probable | Remède |
|---|---|---|
| `Unable to read the extension 'live'` | `_extensions/` non commité | `git add pedagogie/_extensions/ && git commit && git push` |
| `Unable to publish to GitHub Pages (the remote origin does not have a branch named "gh-pages")` | Tu utilises `quarto-actions/publish` au lieu de `peaceiris/actions-gh-pages` | Cf. §5.2 |
| `Error in library(knitr) : there is no package called 'knitr'` | Le step « Install R packages » n'a pas tourné ou a échoué | Vérifier la sortie de `Rscript -e 'install.packages(...)'` dans les logs |
| `404` sur `/_commons/data/...` en runtime | `resources:` manquant dans `_quarto.yml` | Ajouter `- "_commons/data/**"` |
| Aucune erreur mais l'output HTML n'a pas les cellules WebR | knitr a effacé les blocs `{webr}` via un engine no-op | Retirer toute ligne `knitr::knit_engines$set(webr = ...)` |
| Build OK mais cellule WebR bloque sur un package | Le package est dans `webr.packages:` mais absent de repo.r-wasm.org | Retirer le package, trouver un substitut |

## 11. Pour aller plus loin

Documentation officielle :

- Quarto : <https://quarto.org/docs/guide/>
- quarto-live (WebR) : <https://r-wasm.github.io/quarto-live/>
- WebR : <https://docs.r-wasm.org/webr/latest/>
- GitHub Pages : <https://docs.github.com/en/pages>
- GitHub Actions Quarto : <https://github.com/quarto-dev/quarto-actions>

Ressources internes :

- `pedagogie/manuel_animateur.md` — conventions pédagogiques et workflow d'animation.
- `environnement_technique/guide_installation.md` — installation pour participants.
- `_commons/helpers/fetch_data.R` — chargement des datasets avec fallback local.
