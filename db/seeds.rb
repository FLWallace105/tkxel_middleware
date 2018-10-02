# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
admin = User.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password', is_admin: true,  name: 'Waqas Zafar', confirmed_at: Time.now) unless User.find_by_email('admin@example.com')



#fambrands all stores

Brand.create!(name: ENV['ZOBHA_SHOP_NAME']) unless Brand.find_by_name(ENV['ZOBHA_SHOP_NAME'])
Brand.create!(name: ENV['MARIKA_SHOP_NAME'])  unless Brand.find_by_name(ENV['MARIKA_SHOP_NAME'])
Brand.create!(name: ENV['ELLIE_SHOP_NAME'])  unless Brand.find_by_name(ENV['ELLIE_SHOP_NAME'])

Brand.all.each do |brand|
  brand.jobs.create!(name: "OrderJob" ,runned_at: Time.now) unless
      brand.jobs.find_by_name('OrderJob')
  admin.user_brands.create(brand_id: brand.id)
end

