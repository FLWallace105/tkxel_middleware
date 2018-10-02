class AddXmlRequestAndXmlResultToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :xml_request, :string
    add_column :orders, :xml_result, :string
  end
end
