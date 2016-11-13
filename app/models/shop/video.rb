class Shop::Video < ActiveRecord::Base
  belongs_to :videoable, polymorphic: true

  def key=(val)
    super CGI.escape(CGI.unescape(val.to_s))
  end

  def key_url
    ("http://" + Settings.qiniu["host"] + "/" + key).to_s
  end

  cattr_accessor :manage_fields do
    %w[ id video_id video_type key ]
  end

end
