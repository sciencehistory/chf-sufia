require 'resque/server'

Rails.application.routes.draw do
  # this will fall through to ./views/application/robots.txt.erb, no need for an action method
  get 'robots.txt', to: "application#robots.txt", format: "text"

  # override sufia's about routing to use a static page instead of a content block
  get 'about', controller: 'static', action: 'about', as: 'about'
  # add a policy page
  get 'policy', controller: 'static', action: 'policy', as: 'policy'
  # override sufia's contact routing to use a static page instead of a form
  get 'contact', controller: 'static', action: 'contact', as: 'contact'
  # add a faq page
  get 'faq', controller: 'static', action: 'faq', as: 'faq'
  # remove help page, replaced with 'faq'
  get 'help', to: redirect('/404')

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  Hydra::BatchEdit.add_routes(self)
  mount Qa::Engine => '/authorities'

  # Administrative URLs
  namespace :admin do
    # Job monitoring
    constraints ResqueAdmin do
      mount Resque::Server, at: 'queues'
    end
  end

  mount Blacklight::Engine => '/'

    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable

  end

  devise_for :users
  # https://github.com/plataformatec/devise/wiki/how-to:-change-the-default-sign_in-and-sign_out-routes
  devise_scope :user do
    get 'login', to: 'devise/sessions#new'
  end

  resources :welcome, only: 'index'
  root 'sufia/homepage#index'


  # Redirect from OLD work URLs to the new ones that we will install/override below.
  # Also we are getting rid of the `parent` URLs.
  get '/concern/generic_works/:id', to: redirect('/works/%{id}')
  get '/concern/generic_works/:id/viewer/:filesetid', to:  redirect('/works/%{id}/viewer/%{filesetid}')
  get '/concern/parent/:parent_id/generic_works/:id', to: redirect('/works/%{id}')
  get '/concern/parent/:parent_id/generic_works/:id/viewer/:filesetid', to: redirect('/works/%{id}/viewer/%{filesetid}')


  curation_concerns_collections
  curation_concerns_basic_routes
  curation_concerns_embargo_management
  concern :exportable, Blacklight::Routes::Exportable.new

  #############
  #
  #  CHF crazy code to remove named route installed by sufia/CC, and install same named route
  #  with different URL. This is indeed confusing and weird, messing with trying to override
  #  already defined Rails resourceful routes and named helpers, which rails doesn't really want
  #  you to do.
  #
  ##############

    # Rails private API to _uninstall_ named route, may break in future
    Rails.application.routes.named_routes.send(:routes).delete(:curation_concerns_generic_work)
    Rails.application.routes.named_routes.send(:routes).delete(:curation_concerns_parent_generic_work)

    # Have to recreate the routes, such that they are at /works, not breaking any use of
    # curation_concerns_generic_work_path helper method.
    namespace :curation_concerns, path: '' do
      resources "generic_works", path: '/works', except: [:index]
    end

    # We want to GET RID of the `/concern/parent` urls, and just use standard /work urls.
    # This is a trick to create the `curation_concerns_parent_generic_work` route helper methods
    # sufia/CC use, to point to ur new desired /work URL. It depends on us having used private
    # Rails API to remove the previosu named route above.
    get "/works/:id", to: "curation_concerns/generic_works#show", params: {parent_id: nil}, as: "curation_concerns_parent_generic_work"


  # there might be a way to get curation_concerns routes to this for us,
  # but don't know it, and this is easy enough and works. Make the viewer
  # URL lead to ordinary show page, so JS can pick it up and launch viewer.
  get '/works/:id/viewer/:filesetid(.:format)' => 'curation_concerns/generic_works#show', as: :viewer
  get '/parent/:parent_id/works/:id/viewer/:filesetid(.:format)' => 'curation_concerns/generic_works#show'
  # our viewer json route
  get '/works/:id/viewer_images_info' => 'curation_concerns/generic_works#viewer_images_info', defaults: {format: "json"}, format: false, as: :viewer_images_info

  # redirect to signed s3
  get '/download_redirect/:id/:filename_key' => "downloads#s3_download_redirect", as: :s3_download_redirect

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # local routes
  get '/opac_data/:rec_num', to: 'opac_data#load_bib'
  mount Hydra::RoleManagement::Engine => '/'

  get '/focus/:id', to: 'synthetic_category#show', as: :synthetic_category


  Hydra::BatchEdit.add_routes(self)
  # Sufia should be mounted before curation concerns to give priority to its routes
  mount Sufia::Engine => '/'
  mount CurationConcerns::Engine, at: '/'
end
