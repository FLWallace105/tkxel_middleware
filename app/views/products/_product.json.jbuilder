json.extract! product, :id, :sku, :default, :product_date, :created_at, :updated_at
json.url product_url(product, format: :json)
