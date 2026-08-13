---
name: new-article
description: Ajouter un nouvel article au site (fichier YAML de métadonnées + vue ERB). À utiliser quand on demande de créer, porter ou publier un article.
---

# Ajouter un article

Un article = deux fichiers : ses métadonnées en YAML, son contenu en ERB.

## 1. Métadonnées — `config/articles/NN-<slug>.yml`

Le préfixe `NN-` (deux chiffres) donne l'ordre d'affichage sur `/articles` : prendre le numéro suivant, ou renuméroter pour insérer.

```yaml
slug: mon-nouvel-article
h1: Titre affiché en haut de page
title: Balise <title> (SEO, peut différer du h1)
description: >-
  Meta description (SEO) et texte de la carte sur l'index.
keywords: [API, Guide métier, DSI]
hero_backdrop_gradient: "linear-gradient(135deg, #decdbd 0%, #d2e2f6 100%)"
image: articles/mon-image.jpg   # optionnel, remplace le gradient sur la carte
sections:
  premiere-section: Libellé dans le sommaire
  recapitulatif: Pour résumer
```

- `keywords` : uniquement des valeurs de `Article::KEYWORD_CATEGORIES` (`app/models/article.rb`) — elles alimentent les filtres de l'index. Nouveau mot-clef = l'ajouter d'abord à la catégorie pertinente.
- `hero_backdrop_gradient` : **toujours entre guillemets** (un `#` précédé d'un espace démarre un commentaire YAML).
- `sections` : les clefs sont les `id` d'ancres, dans l'ordre de la page ; elles génèrent le sommaire. Chaque clef doit correspondre à un `ArticleSectionComponent(id:)` dans la vue.
- `image` : fichier dans `app/assets/images/articles/`.

## 2. Contenu — `app/views/articles/<slug_en_underscores>.html.erb`

Le template est résolu par convention (`Article#template`) : tirets du slug → underscores. Structure :

```erb
<%= render ArticleLayoutComponent.new(article: @article, mentions: mentions) do %>
  <p class="fr-text--lg">Chapô…</p>

  <%= render ArticleSectionComponent.new(id: "premiere-section", label: "Libellé dans le sommaire") do %>
    …
  <% end %>
<% end %>
```

- `mentions:` (optionnel) : cartes solutions en fin d'article, via `solution_card("slug-solution")`.
- Composants disponibles : `ArticleSectionComponent` (id/label alignés sur le YAML, `heading:` si le titre affiché diffère), `ArticleReadMoreComponent`, `ArticleFigureComponent`, `ArticleSpotlightComponent`, `ArticleChecklistComponent`.
- Style DSFR (`fr-text--lg`, `«&nbsp;…&nbsp;»` pour les guillemets français).

## 3. Rien d'autre à câbler

- Routes : `/articles/:slug` est générique, aucune route à ajouter. (Les redirections 301 à plat dans `config/routes.rb` ne concernent que les articles migrés de l'ancien site.)
- Specs : `spec/requests/articles_spec.rb` itère sur `Article::ALL`, le nouvel article est couvert automatiquement.

## 4. Vérifier

1. `docker compose exec web bundle exec rspec spec/requests/articles_spec.rb`
2. Contrôle visuel de `/articles` (carte + filtres) et de la page — sous Chromium **et** Firefox, console sans erreur.
