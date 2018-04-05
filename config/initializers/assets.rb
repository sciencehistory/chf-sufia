# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
# Adding the below due to complaints on rails upgrade from 4.2.2 to 4.2.3. However, default.png *is*
#   in the app/assets folder in sufia, so unsure why this was necessary.
Rails.application.config.assets.precompile += %w( default.png )

# We're going to use sprockets to compile static html error pages
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'html')
Rails.application.config.assets.register_mime_type('text/html', '.html')
