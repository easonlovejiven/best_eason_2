class Core::Banner < ActiveRecord::Base
  mount_uploader :pic, CorePicUploader
  mount_uploader :pic2, CorePicUploader
  after_save :clear_index_cache
  def clear_index_cache
    Rails.cache.delete("index_page_banners")
  end

  belongs_to :creator, -> { where active: true }, class_name: Manage::Editor, foreign_key: "creator_id"
  belongs_to :updater, -> { where active: true }, class_name: Manage::Editor, foreign_key: "updater_id"

  scope :active, -> { where(active: true) }
  scope :phone, -> { where(genre: 'phone') }
  scope :web, -> { where(genre: 'web') }
  scope :published, -> { active.where(published: true) }
  scope :effective, -> { published.where("end_at > ? and start_at < ?", Time.now, Time.now)}
  scope :will_effective, -> { published.where("end_at > ?", Time.now)}
  scope :old_pics, -> { where("template != 'welfare_product' and template != 'welfare_event'") }
  scope :order_sequence, -> { order("sequence asc, id desc") }

  validate :start_at_and_end_at
  def start_at_and_end_at
    errors.add(:end_at, "结束时间请大于开始时间") if end_at <= start_at
  end

  before_save :set_sequence
  def set_sequence
    update_ids = need_update_sequence
    Core::Banner.where(id: update_ids).update_all("sequence=sequence+1") if update_ids.present?
  end

  def need_update_sequence
    banners = Core::Banner.select(:id, :sequence).will_effective.where("sequence >= ? and genre = ?", self.sequence, self[:genre])
    banners = banners.where("id != ?", self.id) if self.id.present?
    banners = banners.order(sequence: :asc)
    return [] if banners.blank?
    update_ids = []
    (self.sequence..banners.last.sequence).to_a.each_with_index do |o, i|
      break unless banners[i].sequence == o
      update_ids << banners[i].id
    end
    update_ids
  end

  cattr_accessor :manage_fields
  self.manage_fields = %w[title link pic pic2 genre description position start_at end_at template template_id sequence]

  def picture_url
    pic.try(:url)
  end

  def pic2_url
    pic2.try(:url)
  end

  ENUM_GENRE = {"phone" => "手机端", "web"=>"网站", "all"=>'全部' }
  ENUM_POSITION = {"home"=> '焦点图', "find"=>"发现", "funding"=>"应援榜", "hot"=> '任务推荐'}
  TEMPLATE = { "活动"=>"shop_event", '应援'=>'shop_funding', '商品'=>'product', "话题"=>"shop_topic", "媒体"=>"shop_media", '问答' => 'qa_question', '专题'=>'shop_subject', '明星'=>'core_star', '用户'=>'core_user', '图片'=>'welfare_letter', '语音'=>'welfare_voice', '福利商品'=>'welfare_product','福利活动'=>'welfare_event'}

  SEQUENCE_LIMIT = 5
  DEFAULT_PICTURE = 'http://qimage.owhat.cn/8.png'
end
