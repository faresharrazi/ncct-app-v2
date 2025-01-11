require "test_helper"

class SharedMainAccountUsersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shared_main_account_users_index_url
    assert_response :success
  end

  test "should get show" do
    get shared_main_account_users_show_url
    assert_response :success
  end

  test "should get new" do
    get shared_main_account_users_new_url
    assert_response :success
  end

  test "should get create" do
    get shared_main_account_users_create_url
    assert_response :success
  end

  test "should get edit" do
    get shared_main_account_users_edit_url
    assert_response :success
  end

  test "should get update" do
    get shared_main_account_users_update_url
    assert_response :success
  end

  test "should get destroy" do
    get shared_main_account_users_destroy_url
    assert_response :success
  end
end
