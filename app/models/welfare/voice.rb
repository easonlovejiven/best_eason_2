class Welfare::Voice < ActiveRecord::Base
  include ActAsActivable
  include Shop::TaskHelper
  include Redis::Objects

  counter :participator

  has_one :shop_task, as: :shop, class_name: "Shop::Task"

  #语音地址
  def default_voice
    ("http://" + Settings.qiniu["host"] + "/" + key).to_s
  end

  #图片地址
  def default_pic
    ("http://" + Settings.qiniu["host"] + "/" + pic_key).to_s
  end

  #上传task 总任务
  def cover_pic
    default_pic
  end
end
