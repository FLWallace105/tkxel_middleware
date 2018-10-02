json.extract! order, :id, :name, :order_detail, :source, :brand_id, :tracking_id, :status, :price, :customer_name, :payment_address, :shiping_address, :created_at, :updated_at
json.url order_url(order, format: :json)
