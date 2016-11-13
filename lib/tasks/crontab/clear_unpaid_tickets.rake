desc "删除20分钟还未付款订单"
task :clear_unpaid_tickets => :environment do
  event_ids = Set.new
  Ticket.time_out.includes(:event).find_each do |ticket|
    event_ids << ticket.event_id
    if ticket.total_fee > 0
      xml = Alipay::Service.single_trade_query(out_trade_no: ticket.order_no)
      result = Hash.from_xml(xml)

      if result.try(:[], "alipay").try(:[], "error") == "TRADE_NOT_EXIST"
        ticket.destroy && print("-#{ticket.id}-".black)
        next
      end

      trade = result["alipay"]["response"]["trade"] rescue next
      if trade["trade_status"] == "TRADE_CLOSED"
        ticket.destroy && print("-#{ticket.id}-".red)
        next
      end

      print("-#{ticket.id}-".green) if ticket.sync_by_alipay(trade)
    end
  end

  Trade.where(["status = 1 AND platform = 'alipay' AND created_at <= ?", Time.now - 22.minutes]).find_each do |ticket|
    ticket.sync_by_alipay
    ticket.orders.each {|order| event_ids << order.event_id }
  end

  TicketType.where(event_id: event_ids.to_a).find_each do |ticket_type|
    ticket_type.buy_count.value = ticket_type.locked_orders.sum(:quantity)
  end
  print "\n"
end
# WAIT_BUYER_PAY