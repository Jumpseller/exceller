require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'csv'
require 'json'
require 'addressable/uri'
require_relative 'helpers/general'
require_relative 'helpers/rest'

enable :sessions
set :session_secret, '*widetail'

DEBUG = false

API_HOST                = "api.jumpseller.com"
API_VERSION             = "v1"
PRODUCTS_URL_LIST       = "http://#{API_HOST}/#{API_VERSION}/products.json" #all products
PRODUCTS_URL_LIST_COUNT = "http://#{API_HOST}/#{API_VERSION}/products/count.json" #all products count
PRODUCTS_URL            = "http://#{API_HOST}/#{API_VERSION}/products"
PRODUCTS_LIMIT          = 50

CATEGORIES_URL_LIST     = "http://#{API_HOST}/#{API_VERSION}/categories.json" #all products
CATEGORIES_URL          = "http://#{API_HOST}/#{API_VERSION}/categories"

get '/' do
  unless session['logged'] == true
    halt erb :index 
  end

  @page = params['page'] ? params['page'].to_i : 1

  success, @products = get_api_data(PRODUCTS_URL_LIST, { :page => @page, :limit => PRODUCTS_LIMIT }, true)

  success, message = get_api_data(PRODUCTS_URL_LIST_COUNT, {}, true)
  @products_count = message["count"]

  success, message = get_api_data(CATEGORIES_URL_LIST, {}, true)
  @categories = message.map{ |cat| { value: cat["category"]["id"], text: cat["category"]["name"]} }
  erb :index
end

get "/product/:id" do
  product_url = "#{PRODUCTS_URL}/#{params["id"]}"
  sucess, response = get_api_data2(product_url)
  response if sucess
end

post "/edit-product" do
  product_update_url = "#{PRODUCTS_URL}/#{params["pk"]}"
  product_to_edit = {params["name"] => params["value"] }
  put_api_data(product_update_url, {'product' => product_to_edit})
  ''
end

post "/edit-product-variant" do
  ids = params["pk"].split('-')
  product_id = ids[0];variant_id = ids[1]
  product_update_url = "#{PRODUCTS_URL}/#{product_id}/variants/#{variant_id}"
  variant_to_edit = {params["name"] => params["value"]}
  put_api_data(product_update_url, {'variant' => variant_to_edit})
  ''
end

post "/edit-product-categories" do
  product_update_url = "#{PRODUCTS_URL}/#{params["pk"]}"
  p product_to_edit = {"categories" => params["value"].map{ |cat_id| { "id" => cat_id}} }
  put_api_data(product_update_url, {'product' => product_to_edit})
  ''
end

get "/delete-product/:id" do
  product_delete_url = "#{PRODUCTS_URL}/#{params[:id]}"
  delete_api_data(product_delete_url)
  redirect "/"
end

post "/sign-in" do
  redirect "/" unless !params["api-login"].empty? && !params["api-token"].empty? # login/token are mandatory

  session['login'] = params["api-login"] 
  session['token'] = params["api-token"]

  session['logged']   = true
  redirect "/"
end

get "/sign-out" do
  session['login']    = nil
  session['token']    = nil
  session['logged']   = false
  redirect "/"
end