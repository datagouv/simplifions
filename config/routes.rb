Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"
  get "about" => "pages#about"

  get "articles" => "articles#index", as: :articles
  get "articles/:slug" => "articles#show", as: :article

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
