require 'rubygems'
require 'savon'

class CIMS


  class << self
    def get_import_records(items, order)
      begin
        line_items = []
        items[:parents].each {|item| line_items << item}
        items[:childs].each {|item| line_items << item}
        xml = generate_order_xml(line_items, order)
        [true, xml]
      rescue => exception

        ErrorService.notify_brand_users_utility(order.brand_id, exception, IMPORT_MIDDLEWARE_NAME)
        return [false, exception.message]
      end
    end

    def post_records_to_cims(message_body, brand_id, order)
      begin
        status = true
        response = cims_client.call(:import_records, xml: message_body).body
        order.update_attributes(xml_request: message_body,xml_result: response.to_xml)
        response = response[:import_records_response][:xml_result][:msg][:results]
        unless response[:@accepted] == 'True'
          status = (response[:record].class == Array ? response[:record].map {|record| record[:errors]}.uniq.compact : response[:record][:errors])
          ErrorService.notify_brand_users_utility(brand_id, status, IMPORT_MIDDLEWARE_NAME)
        end
        status
      rescue => exception
        ErrorService.notify_brand_users_utility(brand_id, exception, IMPORT_MIDDLEWARE_NAME)
        return exception.message
      end
    end

    def fetch_fulfillment_data(brand_id, shop_name, job)
      begin
        fully_fulfilled_pick_tickets = []
        partial_fulfilled_pick_tickets = []
        request_xml = generate_export_xml(shop_name)
        job.xml_request = request_xml
        response = cims_client.call(:export_record, xml: request_xml).body
        job.xml_result = response.to_xml
        job.save
        unless response[:export_record_response][:export_record_result] == '0'
          records = response[:export_record_response][:xml_result][:msg][:msg_body][:record]
          if records.class == Hash
            if records[:record_type] == "ShipOH"
              fully_fulfilled_pick_tickets << records[:pick_ticket]
            elsif records[:record_type] == "ShipLPND"
              partial_fulfilled_pick_tickets = [{pick_ticket: records[:pick_ticket],
                                                 ref_id: records[:reference],
                                                 sku: records[:sku]}]
            end
          else
            fully_fulfilled_pick_tickets = records.map {|record| record[:pick_ticket] if
                record[:record_type] == "ShipOH"}.uniq.compact
            partial_fulfilled_pick_tickets = records.map {|record|
              {pick_ticket: record[:pick_ticket],
               ref_id: record[:reference],
               sku: record[:sku]} if record[:record_type] == "ShipLPND"}.uniq.compact
          end
        end
        [fully_fulfilled_pick_tickets, partial_fulfilled_pick_tickets]
      rescue => exception
        ErrorService.notify_brand_users_utility(brand_id, exception, FULFILLMENT_MIDDLEWARE_NAME)
        [fully_fulfilled_pick_tickets, partial_fulfilled_pick_tickets]
      end
    end

    def fetch_inventory_on_hand brand_id, warehouse
      begin
        response = cims_client.call(:export_on_hand_invetory, xml: generate_update_inventory_xml(warehouse)).body
        response[:export_on_hand_invetory_response][:xml_result][:msg][:msg_body][:record].class == Hash ? [response[:export_on_hand_invetory_response][:xml_result][:msg][:msg_body][:record]] : response[:export_on_hand_invetory_response][:xml_result][:msg][:msg_body][:record]
      rescue => exception
        ErrorService.notify_brand_users_utility(brand_id, exception, INVENTORY_MIDDLEWARE_NAME)
        return []
      end
    end


    def generate_order_xml(line_items, order)
      header_body = {"msg": {"msgHeader":
                                 {"schemaName": "cIMS_ImportOrderHeaders",
                                  "schemaVersion": "V1.1",
                                  "msgSubject": "cIMS_ImportOrderHeaders",
                                  "msgAttribute": "Import",
                                  "msgType": "Import",
                                  "msgFrom": "CIMS",
                                  "CompanyId": "CIMS",
                                  "msgGUID": "CIMS"},
                             "msgBody": {"Record": generate_order_header_and_details(line_items, order)
                             }}}.to_xml
      header_body.gsub! " type=\"integer\"", ""
      header_body.gsub! " type=\"float\"", ""
      header_body.gsub! "      <Record type=\"array\">\n", ""
      header_body.gsub! "        </Record>\n      </Record>\n", "      </Record>\n"
      header_body.gsub! "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  ", " "
      header_body.gsub! "</hash>\n", ""
      starting_xml_string = "<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:int=\"http://webservices.foxfireindia.com/interface\">\n  <soap:Header/>\n  <soap:Body>\n    <int:ImportRecords>\n      <int:xmlData>\n "
      closing_xml_string = "        </int:xmlData>\n    </int:ImportRecords>\n  </soap:Body>\n</soap:Envelope>"
      import_xml = starting_xml_string + header_body + closing_xml_string
    end


    def generate_order_header_body(order)
      formated_cims_array = {"RecordType": "OH",
                             "Action": 'I',
                             "PickTicket": order.details['id'],
                             "SalesOrder": order.details['id'],
                             "CustSKU": '',
                             "OrderType": order.order_type,
                             "OrderDate": order.created_date,
                             "DesiredShipDate": order.created_date,
                             "CancelDate": order_cancelation_date,
                             "Priority": 2,
                             "SoldToId": order.details['customer']['id'].to_s,
                             "SoldToName": "#{order.
                                 details['customer']['first_name']} #{
                                 order.details['customer']['last_name']}",
                             "SoldToAddressLine1": order.
                                 details['customer']['default_address']['address1'],
                             "SoldToCity": order.
                                 details['customer']['default_address']['city'],
                             "SoldToState": order.
                                 details['customer']['default_address']['province_code'],
                             "SoldToCountry": order.
                                 details['customer']['default_address']['country_code'],
                             "SoldToZip": order.
                                 details['customer']['default_address']['zip'],
                             "ShipToName": order.details['shipping_address']['name'],
                             "ShipToAddressLine1": order.details['shipping_address']['address1'],
                             "ShipToAddressLine2": (order.details['shipping_address']['address2'] rescue ""),
                             "ShipToCity": order.details['shipping_address']['city'],
                             "ShipToState": order.
                                 details['shipping_address']['province_code'],
                             "ShipToCountry": order.
                                 details['shipping_address']['country_code'],
                             "ShipToZip": order.details['shipping_address']['zip'],
                             "ShipToResidential": 'Y',
                             "ShipVia": order.ship_via,
                             "CarrierOptions": "PD",
                             "ShipToStore": '',
                             "ShipFrom": order.warehouse_code,
                             "TotalSalesAmount": order.price.to_s,
                             "FreightTerms": "Sender",
                             "BillToAccount": order.details['billing_address']['country'],
                             "BillToAddressName": order.details['billing_address']['name'],
                             "BillToAddressLine1": order.
                                 details['billing_address']['address1'],
                             "BillToAddressCity": order.
                                 details['billing_address']['city'],
                             "BillToAddressState": order.
                                 details['billing_address']['province_code'],
                             "BillToAddressCountry": order.
                                 details['billing_address']['country_code'],
                             "BillToAddressZip": order.details['billing_address']['zip'],
                             "CustPO": order.details['name'],
                             "SourceSystem": order.vendor_name,
                             "Ownership": 'FB',
                             "Warehouse": order.warehouse_code,
                             "UDF4": order.udf4,
                             "UDF5": '',
                             "UDF6": "CC = CREDIT CARD",
                             "UDF8": order.tax_rate,
                             'TotalTax': order.details['total_tax'],
                             "UDF11": "VAS REQUIRED",
                             "BusinessUnit": "FB",
                             "CreatedDate": order.created_date,
                             "CreatedBy": APPLICATION_URL
      }
    end


    def generate_order_header_and_details line_items, order
      formated_cims_array = [generate_order_header_body(order)]
      line_items.each_with_index do |line_item, index|
        record = {
            "RecordType": "OD",
            "Action": 'I',
            "PickTicket": order.details['id'],
            "HostOrderLine": index + 1,
            "SKU": line_item['sku'],
            "UnitsOrdered": line_item['quantity'],
            "UnitsAuthorizedToShip": line_item['quantity'],
            "UnitSalePrice": (line_item['pre_tax_price'].present? ?
            adjusted_unit_sale_price(line_item['pre_tax_price'].to_f,
                                     line_item['quantity'].to_i) :
                line_item['price'].to_f),
            "UDF2": 1,
            "BusinessUnit": "FB",
            "CreatedDate": order.created_date,
            "CreatedBy": APPLICATION_URL
        }
        record["UDF1"] = 'Final Sale' if final_sale(line_item)
        formated_cims_array << record
      end
      formated_cims_array
    end

    def generate_export_xml(shop_name)
      export_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n  <soap:Body>\n    <ExportRecord xmlns=\"http://webservices.foxfireindia.com/interface\">\n      <ExportBatch>0</ExportBatch>\n      <IntegrationType />\n      <TransType />\n      <Ownership />\n      <SourceSystem />\n      <BusinessUnit>FB</BusinessUnit>\n      <UserId />\n      <XmlData>\n          <msg>\n            <msgHeader>\n              <schemaName>cIMS_ExportRecords</schemaName>\n              <schemaVersion>V1.0</schemaVersion>\n              <msgSubject>ExportRecords</msgSubject>\n              <msgAttribute>Export</msgAttribute>\n              <msgType>Export</msgType>\n              <msgFrom>CIMS</msgFrom>\n              <CompanyId>CIMS</CompanyId>\n              <msgGUID>CIMS</msgGUID>\n              <SourceSystem>#{shop_name}</SourceSystem>\n              <SecurityKey>\n              </SecurityKey>\n            </msgHeader>\n          </msg>\n      </XmlData>\n    </ExportRecord>\n  </soap:Body>\n</soap:Envelope>\n"
    end

    def generate_update_inventory_xml(warehouse)
      inventory_xml = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:int=\"http://webservices.foxfireindia.com/interface\">\n   <soapenv:Header/>\n   <soapenv:Body>\n      <int:ExportOnHandInvetory>\n         <int:Warehouse>#{warehouse}</int:Warehouse>\n      </int:ExportOnHandInvetory>\n   </soapenv:Body>\n</soapenv:Envelope>\n"
    end

    def order_cancelation_date
      (Time.now + 2.days).to_date.strftime("%m/%d/%Y")
    end

    def adjusted_unit_sale_price(pre_tax_price,quantity)
      unit_price = (pre_tax_price/quantity).round(4)
    end

    def cims_client
      Savon.client(wsdl: Rails.root.to_s + ENV['wsdl_file'],endpoint: ENV['cims_url'])
    end

    def final_sale line_item
      line_item['properties'].select {|property| property['name'].downcase == "final sale"}.first['value'] == "true" rescue false
    end
  end


end
