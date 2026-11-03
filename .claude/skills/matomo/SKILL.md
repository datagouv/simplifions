---
name: matomo
description: Consulter les statistiques de simplifions.data.gouv.fr dans Matomo (visites, pages, recherches, évènements, objectifs, liens sortants) ou en modifier les réglages (objectifs, paramètres exclus, segments). À utiliser quand on demande « va voir Matomo », « combien de visites », « quelles pages », « les stats », ou de changer un réglage Matomo.
---

# Matomo de Simplifions

- Serveur : `https://stats.data.gouv.fr`, Matomo 5.
- Site : `idSite=311` (simplifions.data.gouv.fr), fuseau Europe/Paris.
- Droits du jeton : administrateur du site 311 (lecture et réglages du site) ; pas super-utilisateur (ni comptes, ni réglages globaux).

## Le jeton

Il est dans `.matomo/jeton-matomo.txt`, ignoré par git.

- Ne jamais lire, afficher, copier ni répéter ce fichier, ni le mettre dans une variable affichée, une URL, un fichier du dépôt, un artefact ou un message.
- Le passer uniquement par curl, en POST, lu directement depuis le fichier :

```bash
curl -s -X POST "https://stats.data.gouv.fr/index.php?module=API&format=json&idSite=311&method=VisitsSummary.get&period=month&date=last3" \
  --data-urlencode "token_auth@.matomo/jeton-matomo.txt"
```

- Lancer depuis la racine du dépôt (ou du worktree où se trouve `.matomo/`). Si le fichier manque ou si Matomo répond `token_auth` invalide : dire à l'utilisatrice de créer un jeton dans Matomo (Administration › Personnel › Sécurité › Jetons d'authentification) et de le coller seul dans `.matomo/jeton-matomo.txt`.
- Paramètres qui contiennent des espaces ou des caractères spéciaux (segment, nom d'objectif) : les passer en `-d`/`--data-urlencode`, pas dans l'URL.

## Consulter

Paramètres de période : `period=day|week|month|year|range`, `date=today|yesterday|YYYY-MM-DD|lastN|previousN` (avec `range` : `date=2026-10-01,2026-10-31`). Ajouter `filter_limit=N` (ou `-1` pour tout) et `flat=1` pour les rapports hiérarchiques.

| Question | Méthode |
|---|---|
| Visites, visiteurs, rebond, temps moyen | `VisitsSummary.get` |
| Pages les plus vues | `Actions.getPageUrls` (`flat=1`) ou `Actions.getPageTitles` |
| Pages d'entrée / de sortie | `Actions.getEntryPageUrls`, `Actions.getExitPageUrls` |
| Recherches du catalogue | `Actions.getSiteSearchKeywords`, `Actions.getSiteSearchNoResultKeywords`, `Actions.getSiteSearchCategories` |
| Liens sortants (DataPass, sites de solutions…) | `Actions.getOutlinks` (`flat=1`) |
| Évènements | `Events.getCategory`, `Events.getAction`, `Events.getName` (`secondaryDimension=eventAction` pour croiser) |
| Objectifs et conversions | `Goals.getGoals` (liste), `Goals.get` (`idGoal=N` pour un seul) |
| D'où viennent les visiteurs | `Referrers.getReferrerType`, `Referrers.getWebsites`, `Referrers.getSearchEngines` |
| Appareils, navigateurs | `DevicesDetection.getType`, `DevicesDetection.getBrowsers` |
| En direct | `Live.getCounters&lastMinutes=30` |
| Rapports disponibles | `API.getReportMetadata` |

Pour filtrer (ex. visites mobiles, une page précise), `segment=` avec la syntaxe Matomo (`deviceType==smartphone`, `pageUrl=@/demarches/`), url-encodé.

Le sens des évènements (catégorie = zone de la page, action, nom) est défini dans `app/helpers/matomo_helper.rb`, les attributs `data-matomo-*` des vues, et décrit dans `.claude/skills/simplifions-verify/features/matomo.md` et `matomo-evenements.md`. Les lire pour expliquer un chiffre plutôt que deviner.

### Rendre la réponse

- Répondre en mots simples, avec la période exacte et les chiffres utiles, pas le JSON brut.
- Comparer avec la période précédente quand ça aide à lire un chiffre (`date=last2`).
- Signaler ce qui peut fausser la lecture : les administrateurs connectés ne sont pas mesurés, les paramètres de filtres du catalogue sont exclus des URL, les données du jour sont partielles.
- Un graphique seulement si on le demande ou s'il dit mieux qu'une phrase : charger le skill `dataviz` d'abord.

## Modifier un réglage

Une modification change les statistiques de toute l'équipe et n'a pas d'annulation dans Matomo.

1. Lire l'état actuel (`SitesManager.getSiteFromId`, `Goals.getGoals`, `SegmentEditor.getAll`, `CustomDimensions.getConfiguredCustomDimensions`…).
2. Dire en une ou deux phrases ce qui va changer, avant/après, et ce que ça change pour les stats (ex. « les données passées ne sont pas recalculées »).
3. Attendre un oui explicite de l'utilisatrice.
4. Appliquer, puis relire pour vérifier et dire le résultat.

| Réglage | Méthode |
|---|---|
| Paramètres d'URL exclus, IP ou robots exclus, recherche interne | `SitesManager.updateSite` (passer seulement les champs à changer, ex. `excludedQueryParameters`, `excludedUserAgents`, `siteSearch`) |
| Ajouter / modifier un objectif | `Goals.addGoal`, `Goals.updateGoal` (`idGoal`, `name`, `matchAttribute`, `pattern`, `patternType`, `description`) |
| Segments enregistrés | `SegmentEditor.add`, `SegmentEditor.update` |
| Annotations sur la courbe (mise en prod, campagne) | `Annotations.add` (`date`, `note`) |

- `SitesManager.updateSite` remplace une liste entière (ex. `excludedQueryParameters`) : renvoyer la liste complète, anciennes valeurs comprises.
- Supprimer (objectif, segment, annotation) seulement sur demande explicite de cet élément précis.
- Ne jamais envoyer de visite ou d'évènement de test au site 311 (`matomo.php`) : ils fausseraient les vraies stats. Pour tester le marquage, voir `simplifions-verify` (site factice 999999).
- Un réglage qui demande d'être super-utilisateur échoue avec « requires a 'superuser' access » : le dire, et proposer de demander à l'équipe data.gouv qui administre stats.data.gouv.fr.
