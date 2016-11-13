class Core::Sign < ActiveRecord::Base
  belongs_to :user, class_name: "Core::User"
end
