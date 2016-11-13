class Shop::Comment < ActiveRecord::Base
  include ActAsActivable
  include Redis::Objects

  belongs_to :user, class_name: "Core::User", foreign_key: :user_id
  belongs_to :task, polymorphic: true, class_name: "Shop::Comment"

  after_create :update_subject_comments_count

  def update_subject_comments_count
    self.task.comments_subject_participator.incr if task_type == "Shop::Subject"
  end
end
