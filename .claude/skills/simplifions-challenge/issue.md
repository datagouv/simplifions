# What an issue holds

Read by `/simplifions-challenge` before it drafts an issue for Linear, and by any session that drafts one. Issues are written in French. The top is for the PO, who decides and checks; below the line, links and decisions for the dev. An issue the PO must read twice has failed.

## Types and titles

| Type | Prefix | When | Title says |
| --- | --- | --- | --- |
| Story | `US —` | a user sees or does something new, or stops seeing something | what will be true once done |
| Technical task | `TS —` | nothing changes on screen, or a change nobody asked for | what will be true once done |
| Bug | `Bug —` | something that should work does not | the wrong behaviour, as the user sees it |

The title is in the user's words, never the cause or the task, and without negation: « ne la met plus en ligne aussitôt » reads as the defect and the fix at once.

## Shapes

```
Story, task                         Bug
───────────                         ───
Pourquoi                            Ce qui ne va pas
  what they do and see today,         the rule, in the product's word,
  then what they cannot do;           then what does not follow it;
                                      one wrong behaviour per bug
À trancher        (while open)      Reproduire
  ### Question 1, its context,        steps ending on « constater que … »
  the question in bold,               Comportement attendu: the rule
  > **Proposé :** …                   that must hold, not the screen
                                    À trancher        (while open)
Critères
Hors périmètre                      Hors périmètre
────────
Pour le dev
  Liens : the requester, the mockup and its author, the related
  tickets, the meeting note.
  Décisions : what was decided outside Linear and is not already
  above, said as the decision itself.
```

Each section is a level-2 heading with its emoji: `## 💡 Pourquoi`, `## 🐞 Ce qui ne va pas`, `## 🔁 Reproduire`, `## 🎯 Comportement attendu`, `## 🤔 À trancher` (each question a `### Question N`), `## ✅ Critères`, `## 🚫 Hors périmètre`, `## 🛠️ Pour le dev`. A bug has no Critères: its steps and its expected behaviour are the check. Nothing else below the line: the cause, the files and the edge cases are what `/simplifions-plan` finds in the code. A decision is its content, never who took it, when, or how.

## Example

```
Bug — Une donnée utile modifiée est publiée immédiatement

## 🐞 Ce qui ne va pas
Dans l'admin, une modification d'une démarche publiée passe d'abord en
brouillon : le site garde l'ancienne version jusqu'à la publication de la
démarche. Ses recommandations suivent la même règle.

Les données utiles ne respectent pas ce processus et sont immédiatement
publiées après avoir été modifiées.

## 🔁 Reproduire
1. Sur le site, ouvrir la page d'une démarche publiée. Dans la carte d'une
   solution recommandée, repérer une ligne du tableau « Endpoints utiles de
   l'API ».
2. Dans l'admin, ouvrir cette démarche, modifier la description de cette
   donnée utile, enregistrer.
3. Recharger la page sur le site : constater que la nouvelle description est
   déjà en ligne.

## 🎯 Comportement attendu
Une donnée utile modifiée attend la publication de sa
démarche, comme toute recommandation.

## 🚫 Hors périmètre
- Supprimer une donnée utile reste immédiat, comme pour une solution recommandée.

────────
## 🛠️ Pour le dev
Décisions : une donnée utile n'a plus ses propres boutons « Publier » et
« Masquer ». Les 286 données utiles en ligne aujourd'hui le restent après le
déploiement.
```

## Rules

- **Necessary and sufficient.** What lets the issue be investigated, never the solution: about five sentences for the why, about three criteria. Each thing is said once, and the title, criteria, exclusions and decisions say the same thing.
- **Simple.** Written as one says it to a colleague: short sentences, the words on the screen, an example rather than a rule. No dev word above the line (endpoint, modal, a class name), except a label quoted as the screen shows it. An action names its object: « la publication de la démarche », never « la publication » alone.
- **A bug shows how it works before what breaks**: the mechanism in the product's word, in one sentence, then what does not follow it, said in full. A second wrong behaviour is its own bug, linked.
- **The mockup is the spec for the screen.** A screen criterion says « comme la maquette » with the capture; prose only for what a capture cannot show (a click, a sort, an empty state). A difference from it is settled with the user before posting.
- **A criterion is one check** anyone can run in the app or the data, in one sentence; a rule beats its list of cases. Each user the change touches keeps a criterion for their usual path. Every exclusion carries its reason; a challenge no-go always goes on the issue.
- **A question never assumes its answer**, and never reopens what the requester, the mockup or a recorded decision settles; while open, the criteria it changes say « si la réponse proposée est retenue ».
- **Someone else's issue is never rewritten.** The lines it lacks go under « Critères ajoutés au challenge », once the user has agreed to them. A later decision changes the lines it touches in place, and a comment says what changed and why. A rewrite of our own issue changes the words, not the meaning: what the template leaves out (a cause, files, a technical note) is listed for the user with the draft, never dropped silently.
