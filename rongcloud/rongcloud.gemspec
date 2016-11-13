#encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rongcloud/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rongcloud"
  s.version     = Rongcloud::VERSION
  s.authors     = ["plusor"]
  s.email       = ["plusor@icloud.com"]
  s.homepage    = "http://github.com/plusor/rongcloud-sdk"
  s.summary     = "融云SDK."
  s.description = "融云SDK."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "httparty"

  s.add_development_dependency "sqlite3"
end
