# Guide d'installation — Atelier IFORD × GDSG 2026

> **Public** : participants à l'atelier R-Spatial (niveau débutant) + animateur (Ramesesse Dzita).
> **Objectif** : disposer d'un environnement R complet, **identique** sur toutes les machines, en moins de 90 minutes.
> **OS de référence** : Windows 11. Notes équivalentes macOS et Linux à chaque étape.
>
> Ce guide a été validé en direct sur la machine de l'animateur le **15 juin 2026**, avec captures d'écran et versions précises. Toute déviation devra être tracée.

---

## Plan d'installation

| # | Composant | Version cible | Durée |
|---|---|---|---|
| 1 | Vérifications pré-requis | — | 2 min |
| 2 | R | 4.4.x | 5 min |
| 3 | RStudio Desktop | 2024.04+ | 5 min |
| 4 | Quarto CLI | 1.5+ | 5 min |
| 5 | Git | 2.43+ | 5 min |
| 6 | RTools (Windows uniquement) | 4.4 | 10 min |
| 7 | Configuration Git + paire SSH | — | 5 min |
| 8 | Posit Cloud (compte secours) | — | 3 min |
| 9 | Vérification finale | — | 10 min |
| 10 | QGIS LTR (optionnel) | 3.34 LTR | 10 min |
| 11 | Docker Desktop (optionnel, plan B) | dernière | 15 min |

**Total minimal** : ~50 min (étapes 1-9, sans QGIS ni Docker).

---

## 0. Conventions du guide

- **`>>>`** = action à effectuer.
- **`✓`** = ce que vous devriez voir une fois l'action réussie.
- **`⚠`** = piège fréquent à anticiper.
- **`💡`** = astuce ou alternative.

Versions installées sur la machine de référence (à compléter au fur et à mesure de la séance) :

| Composant | Version | Date d'install | Vérif |
|---|---|---|---|
| Système | Windows (PowerShell 5.x) | 2026-06-15 | ☑ |
| R | **4.6.0 ucrt** (2026-04-24, « Because it was There »), x86_64-w64-mingw32/x64 | 2026-06-15 | ☑ |
| RStudio | **2026.05.0+218** Desktop | 2026-06-15 | ☑ |
| Quarto | **1.9.38** (Pandoc 3.8.3, Dart Sass 1.87.0, Deno 2.4.5, Typst 0.14.2) | 2026-06-15 | ☑ |
| Git | **2.52.0.windows.1** + Git Credential Manager | 2026-06-15 | ☑ |
| RTools | **4.5** (en attendant RTools 4.6 ; coexistence OK avec R 4.6.0 grâce à UCRT) | 2026-06-15 | ☑ |
| QGIS | _à renseigner_ | _à renseigner_ | ☐ |
| Docker | _à renseigner_ | _à renseigner_ | ☐ |

---

## 1. Vérifications pré-requis

### 1.1 Vérifier que R n'est pas déjà installé

Ouvrir **Windows PowerShell** (Touche Windows → taper « powershell » → Entrée). Coller la commande suivante :

```powershell
Test-Path 'C:\Program Files\R'
```

- `True` → R est déjà installé. Passer à l'étape 1.2 pour récupérer la version.
- `False` → R n'est pas installé. Aller en §2.

> ⚠ **Piège PowerShell.** Ne pas taper `R --version` : dans PowerShell, `R` est un alias pour `Invoke-History`. Vous obtiendrez l'erreur « Cannot locate the history for command line --version ». Utiliser `R.exe --version` ou `Get-Command R.exe`.

### 1.2 Lister les versions R installées (si R est présent)

```powershell
Get-ChildItem 'C:\Program Files\R' -Directory | Select-Object Name
```

---

## 2. Installer R 4.6.0

### 2.1 Télécharger l'installeur depuis CRAN

> CRAN = *Comprehensive R Archive Network* — le réseau officiel d'archives qui distribue R dans le monde entier.

1. Ouvrir le navigateur (Chrome, Edge, Firefox, Brave).
2. Aller à <https://cran.r-project.org/bin/windows/base/>.
3. Cliquer sur le gros lien en haut : **« Download R-4.6.0 for Windows »** (~90 Mo).
4. Le fichier `R-4.6.0-win.exe` arrive dans `Téléchargements/`.

### 2.2 Lancer l'installeur

1. Double-cliquer sur `R-4.6.0-win.exe` dans `Téléchargements/`.
2. Windows va demander une **autorisation administrateur** → cliquer **Oui**.
3. Suivre l'assistant :

> ⚠ **Piège très fréquent — l'installeur est bloqué.** Vous verrez :
>
> ```
> Error 4551: An Application Control policy has blocked this file.
> Unable to execute file in the temporary directory. Setup aborted.
> ```
>
> Sur Windows 11 récents, ce blocage vient de **Windows Security** (Smart App Control ou Windows Defender Application Control), pas forcément d'un antivirus tiers. Sur Windows 10 et antérieurs, c'est plus souvent l'antivirus (Kaspersky, ESET, Sophos).
>
> **Méthode 1 — Débloquer le flag « Zone.Identifier »** (essayer d'abord, marche dans 70 % des cas)
> 1. File Explorer → Téléchargements.
> 2. Clic droit sur `R-4.6.0-win.exe` → **Propriétés**.
> 3. Onglet **Général**, tout en bas : cocher **« Débloquer »** (ou « Unblock »).
> 4. **Appliquer** → **OK**.
> 5. Re-double-cliquer sur l'installeur.
>
> **Méthode 2 — Désactiver temporairement Smart App Control / Defender** (validée le 15 juin 2026 sur la machine de R. Dzita)
> 1. Démarrer → **Sécurité Windows** (ou « Windows Security »).
> 2. **Contrôle des applications et du navigateur** → **Paramètres Smart App Control** (s'il existe).
> 3. Cocher **Désactivé**.
> 4. Lancer l'installeur R.
> 5. **Une fois R installé, réactiver Smart App Control** en revenant aux mêmes paramètres.
>
> ⚠ **Selon la version de Windows 11, la réactivation peut être impossible** sans réinstaller proprement Windows (mode « Off » devient permanent). Vérifier dans les paramètres de Sécurité Windows si l'option **« Activé »** est toujours sélectionnable AVANT de désactiver. Sur la machine de R. Dzita, la réactivation a bien fonctionné. Pour les participants en salle, préférer la **Méthode 1** (débloquer Zone.Identifier) ou la **Méthode 3** (clé USB pré-débloquée) qui ne touchent pas aux paramètres de sécurité.
>
> **Méthode 3 — Demander à l'animateur de partager un installeur signé déjà débloqué**
> Ramesesse peut distribuer l'installeur sur clé USB après l'avoir débloqué une fois. Le flag Zone.Identifier ne se propage pas depuis une clé USB (selon les paramètres de Windows Defender).
>
> **Méthode 4 — Antivirus tiers (Kaspersky, ESET, etc.)**
> 1. Ouvrir l'antivirus.
> 2. Paramètres → Menaces et exclusions → **Ajouter une exclusion** pour `R-4.6.0-win.exe`.
> 3. Relancer l'installeur.
>
> En salle IFORD : prévoir 15-30 minutes supplémentaires si plusieurs participants rencontrent ce blocage.

> 💡 **Notification « Part of this app has been blocked » — non bloquante.** Après avoir débloqué le fichier (Méthode 1), vous pouvez voir une notification Windows Security du type :
>
> > *« Part of this app has been blocked. Some features of R for Windows 4.6.0 Setup may not work because we can't confirm who published R-4.6.0-win.tmp that the app tried to load. »*
>
> C'est juste un avertissement informatif : un fichier temporaire interne à l'installeur (`.tmp`) n'a pas pu être signé. **L'installation continue normalement.** Fermer la notification et poursuivre l'assistant.


| Étape | Choix recommandé |
|---|---|
| Langue de l'assistant | **English** (les messages d'erreur seront plus faciles à googler en salle) |
| Licence | **Next** (GPL) |
| Destination Location | **`C:\Program Files\R\R-4.6.0`** (laisser par défaut) |
| Components | **Tout coché** (User installation = on garde 32+64 bits + Message translations + HTML help) |
| Startup options | **No (accept defaults)** |
| Start Menu Folder | **R** (par défaut) |
| Additional Tasks | Laisser coché « Save version number in registry entry » et « Associate with .RData files ». Décocher éventuellement les raccourcis bureau si vous ne voulez pas qu'ils s'accumulent. |

4. Cliquer **Install** → l'installation prend 1-2 minutes.
5. Cliquer **Finish**.

### 2.3 Vérifier l'installation

Dans PowerShell :

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\R.exe' --version
```

> Le `&` est l'opérateur PowerShell pour invoquer un exécutable par son chemin absolu. C'est nécessaire car R n'est pas dans le PATH par défaut.

Sortie attendue :

```
R version 4.6.0 (2026-xx-xx) -- "..."
Copyright (C) 2026 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64
...
```

### 2.4 (Optionnel mais recommandé) Ajouter R au PATH

Pour pouvoir taper simplement `R.exe --version` au lieu du chemin complet :

1. Touche Windows → taper « variables d'environnement » → cliquer **Modifier les variables d'environnement système**.
2. Bouton **Variables d'environnement…**.
3. Dans **Variables utilisateur** : sélectionner **Path** → **Modifier**.
4. **Nouveau** → coller `C:\Program Files\R\R-4.6.0\bin`.
5. **OK** × 3 pour fermer.
6. **Fermer puis rouvrir PowerShell** (le PATH est lu à l'ouverture du shell).
7. Vérifier : `R.exe --version` doit maintenant fonctionner directement.

> 💡 RStudio (étape 3) sait trouver R dans la base de registres Windows même sans modifier le PATH. La modification du PATH sert seulement à utiliser R en ligne de commande.

---

---

## 4. Installer Quarto CLI

### 4.1 Téléchargement

Aller à <https://quarto.org/docs/get-started/>. La page détecte Windows et propose un bouton de téléchargement (`.msi`, ~150 Mo).

### 4.2 Installation

Lancer le `.msi` et suivre les étapes proposées par l'assistant Quarto. Si Windows Security bloque, appliquer la **Méthode 1** (clic droit → Propriétés → cocher Débloquer en bas → OK).

L'installeur ajoute automatiquement Quarto au **PATH système** — pas besoin de configuration manuelle.

### 4.3 Vérifier l'installation — `quarto check`

**Fermer puis rouvrir PowerShell** (pour que le PATH soit pris en compte), puis :

```powershell
quarto --version
quarto check
```

Sortie attendue (machine de R. Dzita, 15 juin 2026) :

```
Quarto 1.9.38
[>] Checking environment information...
      Quarto cache location: C:\Users\<user>\AppData\Local\quarto
[>] Checking versions of quarto binary dependencies...
      Pandoc version 3.8.3: OK
      Dart Sass version 1.87.0: OK
      Deno version 2.4.5: OK
      Typst version 0.14.2: OK
[>] Checking Quarto installation......OK
      Version: 1.9.38
      Path: C:\Program Files\Quarto\bin
[>] Checking R installation...........OK
      Version: 4.6.0
      Path: C:/PROGRA~1/R/R-46~1.0
      knitr: (None)
      rmarkdown: (None)
      The knitr package is not available in this R installation.
      The rmarkdown package is not available in this R installation.
[>] Checking Python 3 installation....OK
      Version: 3.13.4
      Jupyter: (None)
```

### 4.4 Lecture critique du `quarto check`

Trois choses importantes à comprendre dans cette sortie :

1. **« knitr: (None) » et « rmarkdown: (None) »** — ces deux packages R ne sont **pas encore installés**. Ils sont **indispensables** pour rendre un `.qmd` qui contient du code R. On les installera juste après (§6).
2. **« TinyTeX: (not installed) » et « LaTeX: (not detected) »** — sans LaTeX, on ne peut pas rendre en PDF depuis Quarto. À installer en §4.5 si vous voulez la sortie PDF (recommandé pour l'IFORD).
3. **« Jupyter: (None) »** — ignorable. C'est pour les notebooks Python ; nous on fait du R.

### 4.5 (Optionnel mais recommandé) Installer TinyTeX pour la sortie PDF

TinyTeX est une distribution LaTeX légère (~150 Mo) maintenue par Yihui Xie, optimisée pour Quarto/RMarkdown. Une seule commande :

```powershell
quarto install tinytex
```

Ça prend 3-5 minutes. Une fois fini, `quarto check` montrera **« TinyTeX: <chemin> »** au lieu de « (not installed) ».

---

## 5. Installer les packages R essentiels (knitr + rmarkdown)

Dans la console **RStudio** (panneau bas-gauche), copier-coller :

```r
install.packages(c("knitr", "rmarkdown"))
```

→ téléchargement depuis CRAN + compilation (~30 secondes).

Vérifier ensuite dans PowerShell :

```powershell
quarto check
```

Les lignes `knitr` et `rmarkdown` doivent maintenant afficher un numéro de version au lieu de `(None)`.

> 📌 **Plus tard**, on lancera `03_ENVIRONNEMENT_TECHNIQUE/install_packages.R` qui installe les ~50 packages de l'atelier (sf, terra, tmap, spdep, etc.). Ici on n'installe que les deux strictement nécessaires pour que Quarto fonctionne.

---

---

## 6. Installer et configurer Git

### 6.1 Vérifier si Git est déjà installé

Dans PowerShell :

```powershell
git --version
```

Trois cas :

| Sortie | Interprétation | Action |
|---|---|---|
| `git version 2.x.x.windows.x` | Git est installé. | Passer à §6.3 (vérif identité). |
| `git : Le terme 'git' n'est pas reconnu...` | Git n'est pas installé OU pas dans le PATH. | Aller en §6.2. |
| Une erreur PowerShell de type « alias » | Git for Windows installé mais PATH non rafraîchi. | Fermer/rouvrir PowerShell, retester. |

> 💡 Sur Windows, le raccourci **« Git Bash »** sur le bureau ne prouve **pas** que Git est utilisable dans PowerShell — Git Bash ouvre un shell MinGW autonome qui contient son propre `git.exe`. Si `git --version` échoue dans PowerShell, c'est que Git for Windows n'a pas ajouté Git au PATH système (option à cocher lors de l'installeur). On y revient en §6.2.

### 6.2 Cas où Git n'est pas installé

#### 6.2.1 Téléchargement

Aller à <https://git-scm.com/download/win>. Le téléchargement de **Git for Windows** (`Git-2.x.x-64-bit.exe`, ~70 Mo) démarre automatiquement.

#### 6.2.2 Lancer l'installeur

Double-cliquer le `.exe`. Si Windows Security bloque, appliquer la **Méthode 1** documentée en §2.2 (Propriétés → Débloquer).

L'assistant Git for Windows est **long** (~15 écrans). Les choix recommandés pour l'atelier :

| Écran | Choix recommandé |
|---|---|
| License | Next |
| Select Components | Laisser les défauts (Windows Explorer integration, Git Bash, Git GUI). Cocher éventuellement **« Add a Git Bash Profile to Windows Terminal »** si Windows Terminal est installé. |
| Select Start Menu Folder | Laisser `Git` |
| Choosing the default editor used by Git | **« Use Visual Studio Code as Git's default editor »** si VS Code est installé, sinon **« Use Notepad++ »** ou **« Use the Nano editor »** (éviter Vim pour des débutants). |
| Adjusting the name of the initial branch | **« Override the default branch name for new repositories »** → taper `main`. |
| Adjusting your PATH environment | **« Git from the command line and also from 3rd-party software »** (option du milieu, recommandée). C'est ce qui ajoute `git` au PATH Windows. |
| Choosing the SSH executable | **« Use bundled OpenSSH »** |
| HTTPS transport backend | **« Use the OpenSSL library »** |
| Configuring line ending conversions | **« Checkout Windows-style, commit Unix-style line endings »** (= `core.autocrlf=true`) |
| Configuring terminal emulator | **« Use Windows' default console window »** (PowerShell-compatible) |
| Default behavior of `git pull` | **« Fast-forward or merge »** (le plus simple pour débutants) |
| Credential helper | **« Git Credential Manager »** (obligatoire pour OAuth GitHub) |
| Extra options | Laisser les défauts (file system caching, symbolic links si demandé). |
| Experimental options | **Tout décocher** |

Cliquer **Install**, puis **Finish**.

#### 6.2.3 Vérifier (rouvrir PowerShell d'abord !)

**Fermer et rouvrir PowerShell** (pour rafraîchir le PATH), puis :

```powershell
git --version
```

Sortie attendue : `git version 2.52.0.windows.1` (ou plus récent).

### 6.3 Configurer l'identité Git (cas où Git est déjà installé OU vient de l'être)

#### 6.3.1 Vérifier la config actuelle

```powershell
git config --global user.name
git config --global user.email
```

Si les deux retournent vide → identité non configurée, suivre §6.3.2.
Si elles retournent déjà votre nom/email → vérifier que c'est bien l'identité que vous voulez pour cet atelier (et passer à §6.4).

#### 6.3.2 Définir l'identité

Adapter les valeurs ci-dessous à votre nom + email réels.

```powershell
git config --global user.name "Prénom Nom"
git config --global user.email "email@institution.org"
git config --global init.defaultBranch main
```

> ⚠ Le **même email** doit être utilisé sur GitHub pour que les commits soient attribués à votre compte (§6.5). Si vous avez un compte GitHub avec un email institutionnel mais un Git local sur l'email perso, les commits apparaîtront comme « anonymes » sur GitHub.

#### 6.3.3 (Recommandé Windows) Forcer la conversion CRLF/LF

```powershell
git config --global core.autocrlf true
```

→ commit en LF (Unix), checkout en CRLF (Windows). Évite les diffs parasites sur les fichiers texte quand le dépôt est partagé avec macOS/Linux.

### 6.4 Vérifier la configuration complète

```powershell
git config --global --list
```

Sortie attendue (au minimum) :

```
user.name=Prénom Nom
user.email=email@institution.org
init.defaultbranch=main
core.autocrlf=true
core.editor="C:\Users\<user>\AppData\Local\Programs\Microsoft VS Code\bin\code" --wait
credential.helper=manager
```

Les deux dernières lignes (`core.editor` et `credential.helper`) sont ajoutées automatiquement par l'installeur Git for Windows si vous avez coché les options recommandées en §6.2.2.

### 6.5 Connecter à GitHub (compte existant)

Au premier `git clone` d'un dépôt privé ou au premier `git push`, **Git Credential Manager** ouvre automatiquement une fenêtre dans le navigateur :

1. Aller sur la page d'autorisation GitHub.
2. Se connecter avec votre compte GitHub.
3. Autoriser **Git Credential Manager** à accéder à vos dépôts.
4. La fenêtre se ferme, le clone/push continue.

→ Pas de mot de passe à stocker, pas de Personal Access Token à gérer.

> 💡 **Si vous n'avez pas encore de compte GitHub** : créer un compte gratuit sur <https://github.com/signup>. Le forfait gratuit suffit pour l'atelier (dépôts publics et privés illimités, GitHub Pages gratuit, Actions limité mais suffisant).

#### 6.5.1 Test rapide (optionnel)

Cloner un petit dépôt public pour valider la chaîne :

```powershell
cd $env:USERPROFILE\Documents
git clone https://github.com/r-wasm/quarto-live.git test-clone
cd test-clone
git log --oneline | Select-Object -First 5
```

Si vous voyez 5 lignes de commits → chaîne Git+GitHub validée.

Vous pouvez supprimer le dossier après :

```powershell
cd ..
Remove-Item -Recurse -Force test-clone
```

---

---

## 7. Installer RTools (compilation Windows)

### 7.1 À quoi ça sert

La plupart des packages utilisés en atelier (`sf`, `terra`, `tmap`, etc.) ont des **binaires Windows pré-compilés** sur CRAN — pas besoin de RTools pour les installer. Mais quelques packages nécessitent compilation depuis source :

- `wopr` (WorldPop Open Population Repository, installé depuis GitHub).
- `INLA` (modèles bayésiens spatiaux, source uniquement).
- Toute mise à jour de package quand le binaire CRAN n'est pas encore disponible.

Sans RTools, ces installations échouent silencieusement ou avec un message peu clair. On l'installe donc **par précaution**.

### 7.2 Choisir la bonne version

RTools est **versionné parallèlement à R** :

| Version R | RTools officiellement compatible |
|---|---|
| R 4.4.x | RTools 4.4 |
| R 4.5.x | RTools 4.5 |
| R 4.6.x | **RTools 4.6 (à venir)** |

> ⚠ **Situation au 15 juin 2026.** R 4.6.0 est sorti le 24 avril 2026 mais **RTools 4.6 n'est pas encore publié** sur CRAN. La version la plus récente disponible est **RTools 4.5**.
>
> **Solution pratique** : installer RTools 4.5 — il fonctionne avec R 4.6.0 dans la grande majorité des cas (Windows R utilise UCRT depuis R 4.2.0, l'ABI est stable entre versions mineures).
>
> **Vérification à faire avant l'atelier du 27 juillet** : re-consulter <https://cran.r-project.org/bin/windows/Rtools/>. Si RTools 4.6 est disponible, le télécharger et l'installer à la place (sans désinstaller 4.5 — les deux peuvent coexister dans des dossiers séparés, c'est le PATH qui décide).
>
> **Si un package échoue à compiler avec RTools 4.5 + R 4.6.0** : fallback **Posit Cloud** (§9) où l'environnement est garanti cohérent.

### 7.3 Téléchargement

Page d'index : <https://cran.r-project.org/bin/windows/Rtools/>

Page directe RTools 4.5 : <https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html>

Télécharger **`rtools45-x86_64.exe`** (~600 Mo, le téléchargement le plus lourd du guide après QGIS et Docker).

### 7.4 Installation

1. Double-clic `rtools45-x86_64.exe`.
2. Si Windows Security bloque → Méthode 1 (§2.2).
3. Assistant :
   - **Destination** : laisser `C:\rtools45` (chemin court sans espace, intentionnel).
   - **Select Components** : tout coché.
   - **Additional Tasks** : tout coché (notamment **« Add path to user PATH »**).
4. **Install** → **Finish**.

### 7.5 Vérifier l'installation

**Fermer et rouvrir RStudio** (le PATH n'est lu qu'à l'ouverture du process).

Dans la Console RStudio :

```r
Sys.which("make")
Sys.which("g++")
```

Sortie attendue :

```
                          make 
"C:\\rtools45\\usr\\bin\\make.exe" 

                                  g++ 
"C:\\rtools45\\x86_64-w64-mingw32.static.posix\\bin\\g++.exe"
```

### 7.6 Test de compilation

⚠ **Attention.** L'installation classique d'un package CRAN (`install.packages("Rcpp")`) télécharge un **binaire pré-compilé** — RTools n'est **pas** sollicité.

Pour réellement valider que la chaîne de compilation fonctionne :

```r
install.packages("Rcpp", type = "source")
```

Tu verras alors défiler dans la console des lignes du type :

```
gcc -I"C:/PROGRA~1/R/R-46~1.0/include" -DNDEBUG -O2 -c ...
```

C'est la signature d'une compilation RTools en action. ~30 secondes de bruit dans la console mais validation bout-en-bout.

Si compilation échouée → noter l'erreur, basculer sur Posit Cloud pour les packages incriminés, et signaler à `ramondzita@gmail.com` pour mettre à jour le guide.

---

---

## 8. Authentification GitHub (compte avec 2FA activée)

Depuis 2021, GitHub n'accepte plus le mot de passe traditionnel pour HTTPS. Deux voies au choix :

### 8.A — Personal Access Token (PAT) HTTPS *(rapide, 5 min — recommandé pour l'atelier)*

#### 8.A.1 Générer le PAT

1. Aller à <https://github.com/settings/tokens>.
2. **Generate new token → Generate new token (classic)**.
3. Remplir :
   - **Note** : `iford-atelier-2026-laptop` (mémorable pour révocation future).
   - **Expiration** : `90 days` (couvre l'atelier + 1 mois tampon ; pour usage long-terme prendre 1 an ou opter pour SSH §8.B).
   - **Scopes** : cocher **`repo`** (tout le bloc) et **`workflow`** (pour GitHub Actions).
4. Tout en bas : **Generate token**.
5. ⚠ **GitHub affiche le token UNE SEULE FOIS** (format `ghp_...`). Le copier immédiatement.

#### 8.A.2 Utiliser le PAT au premier push

Lors du premier `git push`, Git affiche :

```
Username for 'https://github.com': → taper votre username GitHub
Password for 'https://<user>@github.com': → coller le PAT (rien ne s'affiche, c'est normal)
```

Après ce premier push, **Git Credential Manager** stocke le PAT chiffré dans le **Windows Credential Manager**. Plus aucun prompt jusqu'à expiration du PAT (90 jours).

#### 8.A.3 Cas où le PAT est redemandé

- Le PAT expire à la date choisie.
- Vous avez révoqué manuellement le PAT.
- Vous avez vidé le Windows Credential Manager.

Dans ce cas : régénérer un PAT et le coller au prochain push.

### 8.B — SSH *(plus long, pas d'expiration)*

Pour un usage long-terme et plusieurs dépôts (>1 par mois), SSH est plus pratique.

```powershell
ssh-keygen -t ed25519 -C "votre-email@institution.org"
# Accepter le chemin par défaut, mettre ou pas une passphrase
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
ssh-add ~\.ssh\id_ed25519
Get-Content ~\.ssh\id_ed25519.pub | Set-Clipboard
# La clé publique est dans le presse-papier
```

Puis aller à <https://github.com/settings/keys> → **New SSH key** → coller → **Add SSH key**.

Tester : `ssh -T git@github.com` (accepter le fingerprint au premier appel).

Changer le remote vers SSH dans le dépôt local :

```powershell
git remote set-url origin git@github.com:<user>/<repo>.git
```

---

## 9. Créer le premier dépôt — bonnes pratiques

### 9.1 Dossier dans `Documents\GitHub\` (pas dans OneDrive)

OneDrive et Git peuvent entrer en conflit (locks de synchronisation). Convention :

- **Code et matériel pédagogique versionné** → `C:\Users\<user>\Documents\GitHub\<repo>\`.
- **Documents non versionnés** (plaquette officielle, présentations, notes perso) → `OneDrive\...`.

### 9.2 Créer le dépôt vide sur GitHub

1. <https://github.com/new>.
2. **Repository name** : court, kebab-case (`atelier-r-spatial-iford-2026`).
3. **Public** (nécessaire pour GitHub Pages gratuit).
4. ⚠ Ne **pas** cocher « Add README », « Add .gitignore », « Choose a license » à ce stade — on les ajoutera localement pour éviter le conflit du premier push.

### 9.3 Initialiser localement et pousser

```powershell
$repo = "$env:USERPROFILE\Documents\GitHub\<nom-repo>"
New-Item -Path $repo -ItemType Directory -Force
cd $repo

# Créer un README.md et un .gitignore d'abord (avec un éditeur ou via PowerShell)

git init
git branch -M main
git add .
git commit -m "Initial commit: README and .gitignore"
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

Au premier `git push`, fournir le PAT comme mot de passe (cf. §8.A.2).

---

*(Suite du guide : §10 Posit Cloud, §11 install_packages.R complet, §12 QGIS, §13 Docker.)*
