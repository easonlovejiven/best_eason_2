class RecordingsWorker
  #清除过期订单
  include Sidekiq::Worker
  sidekiq_options queue: 'recordings'

  def perform
    h = {}
    Core::Recording.active.where("created_at > ?", (Time.now-1.days).beginning_of_day).group_by{|o| o.name}.map do |key, v|
      h.merge!({"#{key}" => v.map(&:count).sum})
    end
    arr = h.sort_by{|k, v| v}
    Core::HotRecord.find_by(id: 1).present? ? Core::HotRecord.find_by(id: 1).update(name: arr[-1][0], synonym: arr[-1][0], position: arr[-1][1]) : Core::HotRecord.create(id: 1, name: arr[-1][0], synonym: arr[-1][0], position: arr[-1][1], creator_id: 88)
    (Core::HotRecord.find_by(id: 2).present? ? Core::HotRecord.find_by(id: 2).update(name: arr[-2][0], synonym: arr[-2][0], position: arr[-2][1]) : Core::HotRecord.create(id: 2, name: arr[-2][0], synonym: arr[-2][0], position: arr[-2][1], creator_id: 88)) if arr.size > 2
    (Core::HotRecord.find_by(id: 3).present? ? Core::HotRecord.find_by(id: 3).update(name: arr[-3][0], synonym: arr[-3][0], position: arr[-3][1]) : Core::HotRecord.create(id: 3, name: arr[-3][0], synonym: arr[-3][0], position: arr[-3][1], creator_id: 88)) if arr.size > 3
    h, arr = nil
    return nil
  end
end
