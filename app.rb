require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'csv'
require 'json'
require_relative 'helpers/general'
require_relative 'helpers/rest'

set :bind, 'localhost'
set :tmp_path, ( ENV['RACK_ENV'] == "production" ? File.dirname(__FILE__) + "/tmp" : File.dirname(__FILE__) )
enable :sessions

DEBUG = false

api_host = ENV['RACK_ENV'] == "production" ? "api.jumpseller.com" : "api.localhost"

API_VERSION = "v1"
PRODUCTS_URL_LIST   = "http://#{api_host}/#{API_VERSION}/products/available.json"
PRODUCT_UNIQUE_URL  = "http://#{api_host}/#{API_VERSION}/products/"
PRODUCTS_URL        = "http://#{api_host}/#{API_VERSION}/products"

$products = nil

get '/' do   
  unless session['logged'] == true
    session['login']    = "demostore"
    session['token']    = "PLXJHTEVJYWNXRVRIBYUEDUUGMUKFSQL"
  end

  $products = get_api_data(PRODUCTS_URL_LIST, session['login'], session['token'])
  p "Products fetched:#{$products.count}" if DEBUG
  session['products'] = "loaded"

  erb :index
end

get '/2' do
  erb :index_old
end

post '/products_add' do

  products_raw = params["products"]

  if products_raw.nil? || products_raw.empty?
    session['error'] = "No product information provided!"
    redirect "/"
  end

  products_sanitized = products_raw#.gsub(' ','')
  products = CSV.parse(products_sanitized)

  products.each do |product|

    sku,name,description,price,qty = nil,nil,nil,nil,nil
    if product.size < 2
      session['error'] = "Invalid Data Format: #{product.join(" ")}" + "<br/>" + "Correct syntax: 'wig-01', 'Wiggle', 'Wiggle Collection 01', '11', '0.5'"
      redirect "/"
    end
    sku = product[0]
    name = product[1]
    description = product[2]
    price = product[3]
    stock = product[4]
    stock_unlimited = product[5] == "1" ? true : false
    weight = product[6]
    sku_product = get_api_data(PRODUCT_UNIQUE_URL + "#{sku}.json", session['login'], session['token'])

    product_id = nil
    product_id = sku_product[0]["product"]["id"] if sku_product && sku_product[0] && sku_product[0]["product"] && sku_product[0]["product"]["id"]# 0 because let's assume all SKU's are unique
    if product_id
      session['error'] = "SKU:#{sku} was found!"
      next
    end

    product_to_edit = nil
    product_to_edit = {"sku" => sku, "name" => name, "description" => description, "price" => price, "stock" => stock, "stock_unlimited" => stock_unlimited, "weight" => weight}

    res = post_api_data(PRODUCTS_URL, {'product' => product_to_edit}.to_json, session['login'], session['token'])

    if res[0] != true
      session['error'] = "ERROR (#{res[1]}) : con SKU:#{sku}"
      redirect "/"
    end
  end
  $products = nil #force refresh list
  session['error'] = "Products Added!"
  redirect "/"
end

post '/products_edit' do

  products_raw = params["products"]

  if products_raw.nil? || products_raw.empty?
    session['error'] = "No product information provided!"
    redirect "/"
  end

  products_sanitized = products_raw.gsub(' ','')
  products = CSV.parse(products_sanitized)

  products.each do |product|

    sku,name,description,price,qty = nil,nil,nil,nil,nil
    if product.size < 2
      session['error'] = "Invalid Data Format: #{product.join(" ")}" + "<br/>" + "Correct syntax: 'wig-01', 'Wiggle', 'Wiggle Collection 01', '11', '0.5'"
      redirect "/"
    end
    sku = product[0]
    name = product[1]
    description = product[2]
    price = product[3]
    stock = product[4]
    weight = product[5]
    sku_product = get_api_data(PRODUCT_UNIQUE_URL + "#{sku}.json", session['login'], session['token'])

    product_id = nil
    product_id = sku_product[0]["product"]["id"] if sku_product && sku_product[0] && sku_product[0]["product"] && sku_product[0]["product"]["id"]# 0 because let's assume all SKU's are unique
    if product_id.nil?
      session['error'] = "SKU:#{sku} does not match any product!"
      redirect "/"
    end

    product_to_edit = nil
    if sku_product[0]["product"]["options"].empty?
      product_to_edit = {"price" => price, "stock" => stock}
    else
      product_to_edit = {"options" => [{"values" =>[{"properties" => [{"price" => price, "sku" => sku,"stock" => stock, "stock_unlimited" => false}]}]}] }
    end


    p "Found by SKU:#{product_id}"
    url = "#{PRODUCTS_URL}/#{product_id}"
    res = put_api_data(url, {'product' => product_to_edit}.to_json, session['login'], session['token'])

    
    if res[0] != true
      session['error'] = "ERROR (#{res[1]}) : con SKU:#{sku}"
      redirect "/"
    end
  end
  $products = nil #force refresh list
  session['error'] = "Productos Editados!"
  redirect "/"
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