desc "每分钟检查设置已开始的直播室状态为'正在直播', 已结束的直播室状态为'已结束'"
task :fresh_live_room_status => :environment do
  @started_live_rooms = LeanCloud::CloudQuery.search(cql: search_conditions_when_status_is_not_1)["results"].to_a rescue []
  @started_live_rooms.each do |live_room|
    next if live_room["liveStartAt"].try(:[], "iso").to_time.localtime > Time.now
    LeanCloud::LiveRoom.update(live_room['objectId'], {status: '1'})
    print "Started live room [sourceId:#{live_room['sourceId']}] was set as 'Started' \n"
  end
  print "\n"

  @ended_live_rooms = LeanCloud::CloudQuery.search(cql: search_conditions_when_status_is_not_3)["results"].to_a rescue []
  @ended_live_rooms.each do |live_room|
    next if live_room["liveEndAt"].try(:[], "iso").to_time.localtime > Time.now
    LeanCloud::LiveRoom.update(live_room['objectId'], {status: '3'})
    print "Ended live room [sourceId:#{live_room['sourceId']}] was set as 'Ended' \n"
  end
  print "\n"
end

# 当状态不是“正在直播”
def search_conditions_when_status_is_not_1
  cql = "SELECT * from LiveRoom"
  cql << " WHERE liveStartAt IS EXISTS AND status <> 1 AND status <> 99"
end

# 当状态不是“已结束”
def search_conditions_when_status_is_not_3
  cql = "SELECT * from LiveRoom"
  cql << " WHERE liveEndAt IS EXISTS AND status <> 3 AND status <> 99"
end

