Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount ActiveStorageDB::Engine => "/active_storage_db"

  root "pages#home"
  get "about" => "pages#about"
  get "doctrine-referencement-cas-usages" => "pages#doctrine_cas_usages"
  get "doctrine-referencement-solutions" => "pages#doctrine_solutions"
  get "niveaux-simplification" => "pages#niveaux_simplification"
  get "terms" => "pages#terms"
  get "accessibility" => "pages#accessibility"
  get "sitemap" => "pages#sitemap"

  get "articles" => "articles#index", as: :articles
  get "articles/:slug" => "articles#show", as: :article

  get "demarches" => "demarches#index", as: :demarches
  get "demarches/:slug" => "demarches#show", as: :demarche
  get "solutions" => "solutions#index", as: :solutions
  get "solutions/:slug" => "solutions#show", as: :solution
  get "cas-d-usages", to: redirect(path: "/demarches", status: 301)
  # Anciennes URLs des cas d'usage, conservées pour ne pas casser les 28 liens publiés.
  # Le topic suivi-des-tiers-aides a été renommé côté data.gouv : son ancien slug publié
  # doit rediriger vers le nouveau, avant la règle générique qui préserve le slug.
  get "cas-d-usages/aides-publiques-personnes-morales-et-entreprises-individuelles-suivi-des-tiers-aides",
    to: redirect("/demarches/aides-publiques-entreprises-et-associations-suivi-des-tiers-aides", status: 301)
  get "cas-d-usages/:slug", to: redirect("/demarches/%{slug}", status: 301)

  # Anciennes URLs à plat des articles, conservées pour ne pas casser les liens externes
  %w[
    qu-est-ce-qu-une-api
    apis-franceconnectees
    guide-base-petites-collectivites
    prerequis-et-etapes-integration-api
    vos-interlocuteurs-selon-le-type-d-api
    anticiper-le-parcours-usager-avant-d-integrer-vos-api
  ].each do |slug|
    get slug, to: redirect("/articles/#{slug}", status: 301)
  end
end
