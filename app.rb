require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'csv'
require 'json'
require 'addressable/uri'
require_relative 'helpers/general'
require_relative 'helpers/rest'

enable :sessions, :logging
set :session_secret, '*widetail'

API_HOST                = "api.jumpseller.com"
API_VERSION             = "v1"
PRODUCTS_URL_LIST       = "http://#{API_HOST}/#{API_VERSION}/products/available.json"
PRODUCTS_URL_LIST_COUNT = "http://#{API_HOST}/#{API_VERSION}/products/available/count.json"
PRODUCTS_URL            = "http://#{API_HOST}/#{API_VERSION}/products"
PRODUCTS_LIMIT          = 50

get '/' do
  unless session['logged'] == true
    session['login']          = "demostore"
    session['token']          = "PLXJHTEVJYWNXRVRIBYUEDUUGMUKFSQL"
  end

  @page = params['page'] ? params['page'].to_i : 1

  @products = get_api_data(PRODUCTS_URL_LIST, { :page => @page, :limit => PRODUCTS_LIMIT })
  count = get_api_data(PRODUCTS_URL_LIST_COUNT)
  @products_count = count["count"]

  logger.info "Products fetched: #{@products.count}"
  erb :index
end

post "/edit-product" do
  product_update_url = "#{PRODUCTS_URL}/#{params["pk"]}"
  product_to_edit = {params["name"] => params["value"]}
  put_api_data(product_update_url, {'product' => product_to_edit}.to_json, session['login'], session['token'])
  ''
end

post "/sign-in" do

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