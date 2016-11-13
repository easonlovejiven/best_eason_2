class Shop::Subject < ActiveRecord::Base
    include ActAsActivable#多个model重用方法module
    include Shop::TaskHelper
    include Redis::Objects

    counter :participator
    counter :comments_subject_participator
    counter :read_subject_participator
    counter :like_subject_participator

    mount_uploader :cover1, ShopTopicUploader

    validates :description, length: { maximum: 15000, too_long: "最多输入15000个文字" }
    validates :title, length: { maximum: 5000, too_long: "最多输入5000个文字" }

    belongs_to :user, class_name: "Core::User", foreign_key: :user_id
    belongs_to :creator, class_name: "Core::User", foreign_key: :creator_id
    has_one :shop_task, as: :shop, class_name: "Shop::Task"
    has_many :pictures, class_name: "Shop::Picture", as: :pictureable, dependent: :destroy
    has_many :comments, class_name: "Shop::Comment", as: :task, dependent: :destroy #直播评论

    enum status: { pending: 0, living: 1, closed: 2, accident: 4 }

    validates_presence_of :title
    # validates :title, uniqueness: true
    # validates_presence_of :key
    validates_presence_of :star_list

    def picture_url
      key.blank? ? (cover1.url.present? ? "http://#{Settings.qiniu["host"]}/#{cover1.try(:current_path)}" : nil) : cover1.url.present? ? "http://#{Settings.qiniu["host"]}/#{cover1.try(:current_path)}" : key_url #前端发布后即不可修改
    end

    def key=(val)
      super CGI.escape(CGI.unescape(val.to_s))
    end

    def cover_pic
      picture_url
    end

    def key_url
      ("http://" + Settings.qiniu["host"] + "/" + key).to_s
    end

    cattr_accessor :manage_fields do
      %w[ id title guide description user_id creator_id key cover1 cover1_cache category start_at status live_url storage_url is_share ] << {star_list: []}
    end
end
