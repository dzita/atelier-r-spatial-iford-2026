# Ménage du poste — commandes `del` et `ren` à passer vous-même

> Établi le 31/08/2026. Règle §6.7 du référentiel : je ne peux ni supprimer ni
> renommer sur votre poste. J'écris sous le nouveau nom quand c'est possible, et
> je fournis ici les commandes — à passer par vous, dans une invite de commandes
> Windows (`cmd.exe`), après lecture de la raison technique de chaque ligne.
>
> **Avant toute chose : une branche Git.** Ces commandes détruisent des
> fichiers. Faites `git switch -c menage-31-08-2026` (ou un commit propre de
> l'état actuel) avant de les passer, comme le prescrit §6.7.
>
> **Ce document ne liste que ce qui a été réellement observé sur ce poste.**
> Les fichiers annoncés ailleurs mais introuvables ici sont signalés en §4 comme
> *non trouvés*, sans commande associée — je ne fournis pas de `del` pour un
> fichier que je n'ai pas vu.

---

## 0. Se placer à la racine du projet

```bat
cd /d "C:\Users\PROLOG\OneDrive\MES BUSINESS\atelier-r-spatial-iford-2026"
```

Toutes les commandes ci-dessous sont relatives à cette racine.

---

## 1. J08 — anciens fichiers à un chiffre

> ### ⚠ À NE PAS PASSER TOUT DE SUITE
>
> **Trois agents réécrivent J08, J09 et J10 en ce moment même.** Les nouveaux
> fichiers `*_J08.*` et `*_J09.*` ne sont peut-être pas encore écrits. Si vous
> supprimez les anciens avant que les nouveaux existent, vous vous retrouvez
> avec un dossier-jour vide et rien à comparer.
>
> **Condition à vérifier d'abord**, dans le même terminal :
>
> ```bat
> dir /b "pedagogie\J08_population_haute_resolution\*_J08.*"
> ```
>
> Ne passez les `del` ci-dessous **que si** cette commande liste bien
> `demo_formateur_J08.qmd`, `script_formateur_J08.R`, `script_etudiant_J08.R` et
> `script_etudiant_J08_corrige.R`. Si elle ne renvoie rien ou une liste
> partielle, attendez : la réécriture n'est pas finie.

**Raison technique commune** : règle §0.4 du référentiel — numérotation J01 →
J11 **sur deux chiffres**, partout, renommages inclus. Un dossier
`J08_population_haute_resolution` contenant des fichiers `..._J8.*` fait
coexister deux conventions ; tout script, tout `README` et toute commande
`dir *_J08*` qui s'appuie sur la convention à deux chiffres passe à côté de ces
fichiers.

```bat
cd "pedagogie\J08_population_haute_resolution"

REM demo_formateur_J8.qmd : ancien .qmd source de la journee. Il est remplace
REM par demo_formateur_J08.qmd, qui a une numerotation, un plan de modules et
REM des donnees differents (WorldPop/GHS-POP au lieu de Sentinel-2 + DHS).
REM Le garder ferait cohabiter deux .qmd a la racine du dossier-jour : or
REM distribuer_donnees.R lit TOUS les .R et .qmd de la racine pour en extraire
REM les litteraux "datasets/...". L'ancien reclamerait donc encore CMHR71FL.SAV,
REM DS.geojson et les tuiles Sentinel-2, qui n'ont plus rien a faire dans
REM cette journee (regle 6.4).
del "demo_formateur_J8.qmd"

REM script_formateur_J8.R : miroir executable de l'ancien .qmd. Un script est
REM un DERIVE du .qmd (regle 1.5) : la source disparaissant, le derive n'a plus
REM d'origine et ne peut plus etre regenere ni maintenu.
del "script_formateur_J8.R"

REM script_etudiant_J8.R : trame a trous de l'ancien .qmd. Meme raison.
REM Distribuee telle quelle en salle, elle enverrait les participants chercher
REM des fichiers de donnees qui ne seront pas dans leur datasets\.
del "script_etudiant_J8.R"

REM script_etudiant_J8_corrige.R : corrige de la trame ci-dessus. Meme raison.
del "script_etudiant_J8_corrige.R"

cd ..\..
```

---

## 2. J09 — anciens fichiers à un chiffre

> ### ⚠ Même précaution qu'au §1
>
> ```bat
> dir /b "pedagogie\J09_teledetection\*_J09.*"
> ```
>
> Ne passez les `del` que si les quatre nouveaux fichiers `*_J09.*` sont bien
> listés.

**Raison technique commune** : identique au §1 (règle §0.4, numérotation sur
deux chiffres).

```bat
cd "pedagogie\J09_teledetection"

REM demo_formateur_J9.qmd : ancien .qmd source. Remplace par
REM demo_formateur_J09.qmd. Raison supplementaire, propre a cette journee :
REM l'ancien construit ses sections 4 et suivantes sur les bandes Sentinel-2
REM B03 et B04, qui n'ont JAMAIS ete telechargees (cf. outils\A_RESTAURER.md
REM §2.5) — le NDVI n'y est pas calculable. Le laisser a la racine du
REM dossier-jour ferait reclamer ces fichiers fantomes par
REM distribuer_donnees.R a chaque execution.
del "demo_formateur_J9.qmd"

REM script_formateur_J9.R : derive de l'ancien .qmd (regle 1.5).
del "script_formateur_J9.R"

REM script_etudiant_J9.R : trame a trous derivee de l'ancien .qmd.
del "script_etudiant_J9.R"

REM script_etudiant_J9_corrige.R : corrige de la trame ci-dessus.
del "script_etudiant_J9_corrige.R"

cd ..\..
```

**Note** : `slides.qmd` et `README.md` existent dans J08 et J09 sans suffixe de
numérotation. **Ne les supprimez pas** : ils ne portent pas de numéro dans leur
nom, ils ne sont donc pas concernés par la règle §0.4. Leur *contenu* est mis à
jour par les agents de réécriture.

---

## 3. J10 — `.Rhistory` versionné à tort

**Raison technique** : `.Rhistory` est le journal des commandes tapées dans la
console R. Il est écrit automatiquement par RStudio à la fermeture d'une
session, il ne contient rien de reproductible, et il change à chaque ouverture
du projet — donc il produit un `diff` Git à chaque session, sans jamais rien
apporter. Pire : il conserve en clair tout ce qui a été tapé dans la console, y
compris des chemins locaux ou des essais interactifs qui n'ont pas leur place
dans un dépôt distribué aux participants.

Ce fichier peut être supprimé **immédiatement**, il ne dépend d'aucune
réécriture en cours.

```bat
del "pedagogie\J10_politiques_publiques\.Rhistory"
```

Puis, pour qu'il ne revienne pas — à ajouter au `.gitignore` de la racine s'il
n'y figure pas déjà :

```
.Rhistory
.RData
.RDataTmp
*.rar
```

---

## 4. Autres fichiers versionnés à tort — recherche effectuée, résultat

`REPRISE_J06_J11.md` §3 signale trois autres catégories de fichiers versionnés
à tort. **Elles ont été recherchées par Glob sur tout le dépôt le 31/08/2026 :**

| Motif recherché | Résultat sur ce poste | Commande fournie |
|---|---|---|
| `.Rhistory` | **1 trouvé** — `pedagogie\J10_politiques_publiques\.Rhistory` | oui, §3 |
| `.RData` | **aucun trouvé** | non |
| `.RDataTmp` | **aucun trouvé** | non |
| `*.rar` | **aucun trouvé** | non |

Aucune commande `del` n'est donnée pour `.RData`, `.RDataTmp` et `*.rar` :
ils ont soit déjà été supprimés, soit jamais été synchronisés sur cette copie du
dépôt. Les lignes du `.gitignore` proposées au §3 les couvrent de toute façon
pour l'avenir.

---

## 5. `all_data\` — deux renommages, indépendants de la réécriture

**Raison technique** : ces deux fichiers portent une **espace parasite** après
`CMR_`, alors que **tous** les `.qmd` de J02 à J07 les référencent sans espace
(`"datasets/CMR_household_v1_0_admin_level2.csv"`). `distribuer_donnees.R`
apparie par **égalité exacte de `basename()`** : avec l'espace, l'appariement
échoue et le fichier est rapporté comme absent du magasin, alors qu'il est
là — c'est un faux manquant, qui masque les vrais.

Ces deux commandes peuvent être passées **immédiatement**, elles ne dépendent
d'aucune réécriture en cours.

```bat
cd "pedagogie\all_data"

REM Espace parasite apres CMR_ : le code cherche CMR_household_..., pas CMR_ household_...
ren "CMR_ household_v1_0_admin_level2.csv"  "CMR_household_v1_0_admin_level2.csv"
ren "CMR_ household_v1_0_admin_level2.xlsx" "CMR_household_v1_0_admin_level2.xlsx"

cd ..\..
```

Vérification immédiate après renommage :

```bat
dir /b "pedagogie\all_data\CMR_household*"
```

Doit afficher exactement deux lignes, sans espace après `CMR_`.

**Ne renommez PAS `CMFW71FL.SAV`.** C'est le fichier *enquêteurs* du DHS
(`FW` = fieldworker), pas `CMHR71FL.SAV` ni `CMIR71FL.SAV` mal nommé. La
procédure de vérification est au §4 de `outils\A_RESTAURER.md`, et elle doit
être passée **avant** toute décision.

---

## 6. Ordre recommandé

1. Branche Git (`git switch -c menage-31-08-2026`).
2. **§5** — les deux `ren` de `all_data\` (aucune dépendance, gain immédiat sur
   `distribuer_donnees.R`).
3. **§3** — le `del` du `.Rhistory` et l'ajout au `.gitignore` (aucune
   dépendance).
4. Attendre la fin de la réécriture de J08 et J09.
5. **§1** puis **§2** — vérifier par `dir /b` que les fichiers `*_J08.*` et
   `*_J09.*` existent, **puis seulement** passer les `del`.
6. Relancer `source("outils/distribuer_donnees.R")` et lire le bilan `cat()` de
   fin : il nomme désormais chaque fichier introuvable et chaque copie en échec.
7. Un commit par journée (règle §6.7).
