module InventoryOnHandsHelper
  def inventory_percentage inventory
    (inventory.status == FAIL_INVENTORY_STATUS ||
        inventory.status == FAIL_INVENTORY_STATUS_FOR_CIMS) ?
        '--' : inventory.threshold_percentage.to_i
  end
end
