# Examples

Read from step 1 of `/simplifions-commit` when the shape is in doubt. All from this repo's `git log`.

## Subject only

```
Admin : supprimer une recommandation depuis sa ligne
```
```
Prévisualiser une démarche ou une solution en brouillon
```
```
Import Grist : noter une image qui n'est pas png, jpg ou webp
```
```
Carte de vérif : onglets des fiches démarche et solution
```

## Subject and a why the diff cannot show

```
Un seul rafraîchissement data.gouv pour le job et la tâche

Le rafraîchissement reste hors de l'import Grist : Grist partira, data.gouv reste.
```
```
Admin : refuser une image qui n'est pas png, jpg ou webp

Le type est lu dans le contenu du fichier par Active Storage ; un
fichier sans signature (texte) garde le type de son extension.
```
```
Recommandation publiée : Enregistrer garde un brouillon

Une recommandation ajoutée à une démarche publiée est créée masquée,
marquée pour paraître avec elle.
```

## Before → after

The « after » lines are real subjects; the « before » lines are the drafts they replace.

Three commits for one behaviour, the review loop showing through, become one after autosquash:
```
Admin : afficher la colonne d'état
Admin : corriger la colonne d'état
Admin : colonne d'état, suite review
```
→
```
Toutes les fiches de l'admin : colonne d'état et d'actions
```

A subject that carries its body:
```
Ajouter la possibilité pour l'administrateur de supprimer une recommandation directement depuis la ligne du tableau
```
→
```
Admin : supprimer une recommandation depuis sa ligne
```

A body that retells the diff, cut:
```
Admin : rouvrir l'onglet de la fiche après l'enregistrement

Le contrôleur passe maintenant le paramètre tab à la redirection.
```
→
```
Admin : rouvrir l'onglet de la fiche après l'enregistrement
```
