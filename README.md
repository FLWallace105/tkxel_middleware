# fambrandsfulfillment.com

### prerequisites 
- [Redis](https://redis.io/topics/quickstart)
- [Postgresql](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04)
- Ruby 2.4

### setup
- bundle install
- override config/database.yml
- override config/application.yml
- rails  db:create
- rails  db:migrate
- rails  db:seed

### start

- cd /path/to/project & sidekiq
- cd /path/to/project & rails s
- redis-server
- localhost:3000

### configure
[ngrok](https://ngrok.com/download) can be great tool for implementing and testing webhooks in dev environments. 

Go to Shopify store's settings (www.store-url.com/admin/settings/notifications) and set JSON type webhooks for Action Order payment to https://base-url.com/orders
OR 
run following commands: 

- rake webhook:create_shopify_webhooks 
- rake inventory:populate_inventory
- rake webhooks:recharge:hooks:create