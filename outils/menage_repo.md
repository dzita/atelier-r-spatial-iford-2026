# Toilettage du dépôt — commandes à passer

> Ces commandes sont à passer manuellement : elles suppriment des fichiers,
> l'opération n'est pas réversible. Ouvrir une invite de commandes **à la
> racine du projet** :
>
> ```
> cd /d "C:\Users\PROLOG\OneDrive\MES BUSINESS\atelier-r-spatial-iford-2026"
> ```
>
> Rien ici n'est urgent. Tout ce qui suit est **déjà hors de Git** grâce au
> `.gitignore` : ces commandes ne servent qu'à désencombrer le disque. Elles
> se passent dans l'ordre, ou pas du tout.

---

## 1. Notes de travail — les plus encombrantes

Huit fichiers à la racine, plus un dans `pedagogie/`. Ce sont les diagnostics
qui ont servi à arbitrer. **Les décisions sont consignées dans le code, dans
les `LISEZMOI` et dans les procédures** : ces documents ne servent plus qu'à
retracer le raisonnement.

Ils contiennent le détail chiffré de ce qui a été trouvé : les copier ailleurs
avant de supprimer, pour qui souhaite en garder une trace.

```bat
del "REVUE_J01_J05.md"
del "MANIFESTE_DONNEES_J01_J07.md"
del "MANIFESTE_DONNEES_J08_J10.md"
del "CARTOGRAPHIE_J08_J10.md"
del "CONTROLE_J08_J10.md"
del "GISEMENT_DONNEES_INEXPLOITEES.md"
del "ETAT_DONNEES_J01_J11.md"
del "SUBSTITUTION_FIES.md"
del "pedagogie\_SITE_ETAT.md"
```

**Ce qui reste, et pourquoi.** Ces cinq-là sont opérationnels et se
conservent :

| Fichier | À quoi il sert |
|---|---|
| `PROCEDURE_MISE_EN_PLACE.md` | la marche à suivre pour installer |
| `DEPLOIEMENT_SITE_WEBR.md` | la marche à suivre pour publier |
| `outils\A_RESTAURER.md` | ce qu'il faut remettre et où le trouver |
| `outils\menage_poste.md` | les `del` / `ren` du matériel ancien |
| `pedagogie\J*\_A_FAIRE_J0X.md` | la procédure de recette du premier rendu |

---

## 2. Le rendu périmé du site

`pedagogie\_site\` contient encore le site rendu depuis **l'ancienne
arborescence** — `J01_intro_R_pensee_spatiale`, `J02_sf_CRS_vecteurs`,
`J10_workflows_reproductibles`… Ces dossiers n'existent plus.

À supprimer avant tout `quarto render`, sinon d'anciennes pages orphelines
sont publiées à côté des nouvelles :

```bat
rmdir /s /q "pedagogie\_site"
```

Il sera reconstruit au prochain rendu.

---

## 3. Le matériel ancien remplacé

Les commandes détaillées, avec la raison technique de chaque ligne, sont dans
**`outils\menage_poste.md`**. Elles couvrent :

- les `*_J8.*` et `*_J9.*` de J08 et J09, remplacés par leurs équivalents à
  deux chiffres ;
- les trois anciens scripts à la **racine** de `J10_politiques_publiques`, qui
  portent exactement les noms des nouveaux rangés dans `scripts\` — c'est le
  cas le plus piégeux ;
- `pedagogie\J10_politiques_publiques\.Rhistory`.

**Passer d'abord le contrôle** que ce fichier indique : les nouveaux fichiers
doivent exister avant que les anciens soient supprimés.

---

## 4. Les `LISEZMOI.md` surnuméraires

J01, J02, J04 et J05 portent un `LISEZMOI.md` **à la racine du dossier-jour**,
en plus du `datasets\LISEZMOI.md` prévu par le référentiel. Ils n'ont jamais
été resynchronisés avec le contenu des journées, et celui du J05 ne mentionne
même pas `CMHR71FL.SAV` — le fichier central de la journée.

Ils induisent en erreur plus qu'ils n'informent :

```bat
del "pedagogie\J01_fondations\LISEZMOI.md"
del "pedagogie\J02_penser_espace\LISEZMOI.md"
del "pedagogie\J04_terre_en_pixels\LISEZMOI.md"
del "pedagogie\J05_enquetes_carte\LISEZMOI.md"
```

Le `datasets\LISEZMOI.md` de chaque journée, lui, reste : c'est celui que le
référentiel prévoit (§6.5).

---

## 5. Après le ménage — vérifier ce que Git voit

```
git status
```

La racine ne devrait plus montrer que : `README.md`,
`REGLES_MATERIEL_ATELIER.md`, `REPRISE_J06_J11.md`,
`MANUEL_SUPPORT_TECHNIQUE.md`, `PROCEDURE_MISE_EN_PLACE.md`,
`DEPLOIEMENT_SITE_WEBR.md`, le `.Rproj`, `.gitignore`, `.gitattributes`,
et les dossiers `pedagogie\`, `outils\`, `environnement_technique\`,
`.github\`.

Si un fichier de la section 1 apparaît encore dans `git status`, c'est qu'il
avait **déjà été commité** lors d'un push antérieur : `.gitignore` n'agit que
sur les fichiers non suivis. Dans ce cas :

```
git rm --cached "NOM_DU_FICHIER.md"
```

puis commit. Le fichier reste sur le disque, mais sort de Git.
