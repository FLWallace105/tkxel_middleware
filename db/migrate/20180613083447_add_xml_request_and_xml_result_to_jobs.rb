class AddXmlRequestAndXmlResultToJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :jobs, :xml_request, :string
    add_column :jobs, :xml_result, :string
  end
end
