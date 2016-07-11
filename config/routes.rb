Rails.application.routes.draw do

  # local routes
  get '/opac_data/:rec_num', to: 'opac_data#load_bib'
  mount Hydra::RoleManagement::Engine => '/'

end
