# Avis sur la page

At the end of every article, fiche démarche and fiche solution, the reader answers « Cette page vous a-t-elle été utile ? » by choosing one of three DSFR rich radios with the Je donne mon avis smileys (Non, Moyennement, Oui), then `Envoyer mon avis`, which sends one Matomo event named after the choice, the page as its context; the page thanks the reader, offers a link to write to the team (what is missing after Non or Moyennement, a remark after Oui), the pre-filled « Avis sur une page » e-mail of the contact page, citing the page. `Envoyer mon avis` stays disabled until a choice is made; once sent, the choice is locked.

## Sub-features

- sans-choix: `Envoyer mon avis` is disabled until a smiley is chosen; choosing alone sends nothing.
- vote: sending `Avis sur la page | Trouver la page utile | <choix> (avant lecture|après lecture) — <page>`, locks the choice and thanks the reader, focus on the thanks.
- lecture: the vote says `après lecture` once the page has sent its `Lecture` event (a gesture, 74 % of the page, 30 s visible), `avant lecture` before.
- retour: after Non or Moyennement, the link `Dites-nous ce qui manque` opens the contact page of the fiche; after Oui, the link `Écrivez-nous` to the same page instead.
- unique: after sending, the radios are disabled and `Envoyer mon avis` is gone.

## How to get to it (user POV)

- `/demarches/<slug>` and `/solutions/<slug>`: under the content, just above « Proposer une modification du contenu ».
- `/articles/<slug>`: at the end of the article text.
- Anyone; the votes are read in Matomo › Comportement › Évènements, category `Avis sur la page`.

## Driving it with Capybara

Drive: `features/avis-page.rb` (SKILL.md § Drive).

Preconditions: one visible démarche and one visible fiche solution (Grist import). The drive sets `MATOMO_SITE_ID=999999` and reads the events from the `matomo.php` requests, as in [`matomo-evenements.md`](matomo-evenements.md).

- **Sans choix.** On the first visible démarche, `Envoyer mon avis` is disabled; choose `Moyennement`: it becomes active, no event yet.
- **Vote démarche.** Choose `Non`, click `Envoyer mon avis`: the event `Avis sur la page | Trouver la page utile | Non (avant lecture) — <nom>` is sent, focus moves to `Merci pour votre avis !`, and the link `Dites-nous ce qui manque` to `/contact/donner-son-avis?demarche=<slug>` show.
- **Vote unique.** The three radios are disabled and `Envoyer mon avis` is gone.
- **Vote solution.** On the first visible fiche solution, choose `Oui` and send: its event is sent, `Merci pour votre avis !` shows with the link `Écrivez-nous` to `/contact/donner-son-avis?solution=<slug>`, not `Dites-nous ce qui manque`.
- **Vote article.** On `/articles/qu-est-ce-qu-une-api`, choose `Moyennement` and send: its event is sent, and the link to `/contact/donner-son-avis?article=qu-est-ce-qu-une-api` shows.
- **Vote après lecture.** On `/articles/qu-est-ce-qu-une-api`, press `End` and wait for the `Lecture` event (30 s), then choose `Oui` and send: the event is named `Oui (après lecture) — <titre>`.
- **Mobile.** At 375 px wide, the three rich radios stack in one column.
- **Proof.** Screenshots of the block before and after each vote, desktop and mobile; read-back of the events sent.

## Gotchas

- Never run with `MATOMO_SITE_ID=311`: the votes would land in the real statistics.
- The block sits low on long fiches: Capybara scrolls to the radio before choosing, the screenshot is taken after `scroll_to`.
- The first vote of a run waits up to 10 s for its event: the Matomo tag loads from stats.data.gouv.fr, slower on a cold start.
