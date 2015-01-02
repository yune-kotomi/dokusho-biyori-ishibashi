Ishibashi::Application.routes.draw do
  get 'shelfs/show/:id',
    :controller => :user_products, :action => :show

  resources :keywords
  resources :products, :only => [:show]
  get 'products/to_amazon/:id' => 'products#to_amazon'
  get 'products/to_rakuten/:id' => 'products#to_rakuten'

  resources :user_products

  get 'users/feeds/:id.:format',
    :controller => 'users',
    :to => 'users#feeds'

  get 'users/:domain_name/:screen_name',
    :controller => 'users',
    :to => 'users#show',
    :constraints => {:domain_name => /(.*?)/}

  get 'users/:action',
    :controller => 'users'
  patch 'users/update',
    :to => 'users#update'
  post 'users/update', :to => 'users#update'

  get 'users',
    :controller => 'users',
    :to => 'users#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
