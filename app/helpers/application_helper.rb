module ApplicationHelper
  def admin_access user
    user.is_admin?
  end
  def brands_options_for_select user
    options = []
    all = []
    user.brands.each {|b| options << [b.name,[b.id]]}
    options.each {|op| all << op[1] }
    options.unshift(['All',all.flatten!])
    if session[:selected_brand].nil?
      session[:selected_brand] = all
    end
    options
  end
  def has_multiple_brands user
    user.brands.count > 1
  end

  def has_single_brand user
    user.brands.count == 1
  end

  def single_brand_name user
    brand = user.brands.first
    session[:selected_brand] = [brand.id]
    brand.name.titleize
  end

  def heading name
    case name
      when 'users'
        return 'USER MANAGEMENT'
      when 'inventory_on_hands'
        return ' FAILED INVENTORY'
      when 'reserve_inventories'
        return 'Reserve Inventory'
      when 'fulfillments'
        return 'FAIL FULFILLMENTS'
      else
        name.upcase
    end
  end

  def format_date_time_list(date)
    date.strftime('%m/%d/%y, %H:%M')
  end
  def format_date_time(date)
    date.strftime('%a, %m-%d-%y, %I:%M%p')
  end

end
