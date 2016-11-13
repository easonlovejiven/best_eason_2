class Core::Connection < ActiveRecord::Base
  belongs_to :account, class_name: Core::Account
	scope :active, -> { where(active: true) }
  validates_presence_of :token
  validates_presence_of :identifier
  def picture_url
    return pic.gsub(/\?.*/, "") if pic.to_s.match(/^http\:\/\//)
    pic.present? ? "http://#{Settings.qiniu["host"]}/#{pic}" : 'http://7xlmj0.com1.z0.glb.clouddn.com/o_meio-mei.png'
  end
end
