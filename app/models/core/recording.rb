class Core::Recording < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  belongs_to :user, class_name: Core::User

end
