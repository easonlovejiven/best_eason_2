class Core::TaskAward < ActiveRecord::Base
  include ActAsActivable

  belongs_to :task, polymorphic: true
  belongs_to :user, class_name: Core::User, foreign_key: :user_id
end
