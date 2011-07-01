require File.dirname(__FILE__) + '/../test_helper'

class MeasuresControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def setup
    login_as :aaron
  end

  def test_should_show_measures_index
    get :index
    assert_response :success
    assert_not_nil assigns(:measures)
  end

  def test_should_show_measure
    get :show, :id => measures(:one).id
    assert_response :success
    assert_not_nil assigns(:measure)
  end

  def test_should_get_measure_creation_form
    get :new
    assert_response :success
    assert_not_nil assigns(:measure)
  end

  def test_should_get_measure_edition_form
    get :edit, :id => measures(:one).id
    assert_response :success
    assert_not_nil assigns(:measure)
  end

  def test_should_remove_measure
    assert_difference('Measure.count', -1) do
      delete :destroy, :id => measures(:one).id
      assert_response :redirect
      assert_redirected_to measures_url
    end
  end

  def test_should_create_new_measure
    assert_difference('Measure.count') do
      post :create,
           :measure => { :name => 'bar', :bandwidth => '128' }
      assert_response :redirect
      assert_redirected_to measure_url(assigns(:measure))
    end
  end

  def test_update_measure_properties
    put :update, :id => measures(:one).id, :measure => { :name => 'foo' }
    assert_response :redirect
    assert_redirected_to measure_url(assigns(:measure))
  end
end
