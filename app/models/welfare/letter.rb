class Welfare::Letter < ActiveRecord::Base
  include Redis::Objects
  include Shop::TaskHelper
  # include Core::TaskHelper

  counter :participator

  validates :content, length: { maximum: 5000, too_long: "最多输入5000个文字" }
  validates :title, length: { maximum: 30, too_long: "最多输入30个文字" }

  scope :active, -> { where(active: true) }
  belongs_to :paper
  belongs_to :user, class_name: "Core::User"
  belongs_to :creator, -> { where active: true }, class_name: "Manage::User", foreign_key: "creator_id"
  has_many :images, dependent: :destroy, class_name: Welfare::LetterImage
  has_one :shop_task, as: :shop, class_name: "Shop::Task"

  accepts_nested_attributes_for :images

  cattr_accessor :manage_fields do
    %w[ id title pic paper_id receiver user_id content signature is_share images_attributes ] << {images_attributes: %w{ active id pic }, star_list: []};
  end

  def description
    content
  end

  def picture_url
    pic.blank? ? nil : pic.include?('#') ? "http://#{Settings.qiniu["host"]}/#{pic.try(:current_path)}" : "http://#{Settings.qiniu["host"]}/#{pic}"
  end

  def cover_pic
    picture_url || images.tries(:first, :picture_url)
  end

end
