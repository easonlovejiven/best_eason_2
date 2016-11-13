# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
# Rails.application.config.assets.paths << Rails.root.join("app/assets", "lib", "vendor")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.

Rails.application.config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif *.swf *.ico manage/role/role.js manage/login.js kindeditor.js home/application/shop/cart.js lightbox/lightbox.css lightbox.js jquery.validate.min.js)
# Rails.application.config.assets.precompile += ["manage/role/role.js", "manage/login.js", Rails.root.to_s+"/public/kindeditor/kindeditor.js", "home/application/shop/cart.js", "lightbox/lightbox.css", "lightbox.js", "jquery.validate.min.js"]
# Rails.application.config.assets.precompile += %w( backend.css backend.js manage/login.js manage/role/role.js *.png *.jpg *.jpeg *.gif)
