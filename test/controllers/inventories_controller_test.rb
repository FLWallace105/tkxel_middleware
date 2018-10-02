require 'test_helper'

class InventoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reserve_inventory = inventories(:one)
  end

  test "should get index" do
    get reserveInventories_url
    assert_response :success
  end

  test "should get new" do
    get new_reserveInventory_url
    assert_response :success
  end

  test "should create @reserve_inventory" do
    assert_difference('ReserveInventory.count') do
      post reserveInventories_url, params: {reserve_inventory: {brand_id: @reserve_inventory.brand_id, product_id: @reserve_inventory.product_id, style_id: @reserve_inventory.style_id } }
    end

    assert_redirected_to reserveInventory_url(ReserveInventory.last)
  end

  test "should show @reserve_inventory" do
    get reserveInventory_url(@reserve_inventory)
    assert_response :success
  end

  test "should get edit" do
    get edit_reserveInventory_url(@reserve_inventory)
    assert_response :success
  end

  test "should update @reserve_inventory" do
    patch reserveInventory_url(@reserve_inventory), params: {reserve_inventory: {brand_id: @reserve_inventory.brand_id, product_id: @reserve_inventory.product_id, style_id: @reserve_inventory.style_id } }
    assert_redirected_to reserveInventory_url(@reserve_inventory)
  end

  test "should destroy @reserve_inventory" do
    assert_difference('ReserveInventory.count', -1) do
      delete reserveInventory_url(@reserve_inventory)
    end

    assert_redirected_to reserveInventories_url
  end
end
