NON_FULFILLED_ORDER = "Pick Ticket Not Found at Shopify."
FAIL_INVENTORY_STATUS = "SKU not found at Shopify."
FAIL_INVENTORY_STATUS_FOR_CIMS = "SKU not found at CIMS."
INVENTORY_CHANGE = "% change in Shopify Inventory."
OUT_OF_STOCK = "Out of Stock."
IMPORT_JOB_NAME = 'SyncToCIMSJob'
FULFILLMENT_JOB_NAME = 'FetchFulfillmentBackgroundJob'
UPDATE_INVENTORY_JOB_NAME = 'UpdateInventoryOnHandJob'
INVENTORY_MIDDLEWARE_NAME = 'On-Hand Inventory'
IMPORT_MIDDLEWARE_NAME = 'Import to CIMS'
FULFILLMENT_MIDDLEWARE_NAME = 'Fetch Fulfillment'
APPLICATION_URL = "fambrandsfulfillment.com"
INVENTORY_NOTIFICATION_TYPE = "Inventory Threshold Exceeded -20/20% Limit"
SIDEKIQ_JOB_IMPORT = 'sync_to_cims'
SIDEKIQ_JOB_INVENTORY = 'update_inventory_onhand'
SIDEKIQ_JOB_FULFILLMENT = 'fetch_fulfilment_cron'
ELLIE_ACCESSORIES = ["Accessories","Equipment","Wrap"]
ELLIE_SUBSCRIPTION_FIRST_ORDER_TAG = "Subscription First Order"
ELLIE_SUBSCRIPTION_RECURING_ORDER_TAG = "Subscription Recurring Order"
ELLIE_PRODUCT_TYPES = ["Tops", "Accessories", "Equipment", "Leggings", "Sports Bra", "Jacket", "Wrap", "sports-jacket"]


# if ENV["RAILS_ENV"] == "development" || ENV["RAILS_ENV"] == "staging"
#
#   ELLIE_SHOP_NAME = "elliestaging"
#   MARIKA_SHOP_NAME = "marikastaging"
#   ZOBHA_SHOP_NAME = "zobhastaging"
#   APP_URL = "https://fambrandsfulfillment.com"
#
# elsif ENV["RAILS_ENV"] == "production"
#
#   ELLIE_SHOP_NAME = "ellie"
#   MARIKA_SHOP_NAME = "marika"
#   ZOBHA_SHOP_NAME = "zobha"
#   APP_URL = "https://fambrandsfulfillment.com"
#
# end