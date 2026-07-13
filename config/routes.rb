Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "cv.pdf" => "cv#pdf", as: :cv_pdf
  get "cv" => "cv#show"

  # Writing is disabled until real posts are published. Uncomment to restore.
  # get "writing.rss" => "articles#index", defaults: { format: :rss }, as: :articles_rss
  # get "writing" => "articles#index", as: :articles
  # get "writing/:slug" => "articles#show", as: :article

  get "contact" => "contacts#show"

  get "sitemap.xml" => "pages#sitemap", defaults: { format: :xml }

  # Defines the root path route ("/")
  root "pages#home"
end
