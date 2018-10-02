module OrdersHelper

  def reason_of_order log
    (log.status == "cims_push_failed" || log.status == "partially_fulfilled") ? "Reason/Description: #{log.description}" : ''
  end

  def order_status status
    status.sub! "cims", 'CIMS'
    status.sub! "Cims", 'CIMS'
    status
  end
end
