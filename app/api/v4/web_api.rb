module V4
  class WebApi < Grape::API

    format :json

    before do
      check_sign
    end

    desc "获取王源活动前三"
    params do
    end
    get :get_wangyuan_event_top_three do
      ret = Rails.cache.fetch("wangyuan_top_three_event", expires_in: 1.hour) do
        event = {
          871=>"江苏省", 872=>"北京", 873=>"山东", 874=>"青海", 875=>"河北", 876=>"海南",
          877=>"福建", 878=>"内蒙古", 879=>"贵州", 880=>"广东", 881=>"四川", 882=>"重庆",
          883=>"宁夏", 884=>"广西", 885=>"陕西", 886=>"河南", 887=>"辽宁", 888=>"山西",
          889=>"上海", 890=>"云南", 891=>"安徽", 892=>"新疆", 893=>"湖北", 894=>"湖南",
          895=>"甘肃", 896=>"天津", 897=>"浙江", 923=>"江西省", 924=>"吉林"
        }
        Shop::Event.includes(:ticket_types).where(id: event.keys).map{|c| [c.id, c.task_participator]}.sort{|a, b| b[1]<=>a[1]}[0..2].each_with_index.map{|e,i| {
          top: i+1,
          name: event[e[0]] || '',
          num: e[1] || 0
        }}
      end
      header "Access-Control-Allow-Origin", "*"
      success({ data: ret })
    end
  end
end
