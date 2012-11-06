require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'csv'
require 'json'

set :tmp_path, File.dirname(__FILE__) + "/tmp"
enable :sessions

PRODUCTS_URL = "http://api.vendder.com/bicis.lahsen.cl/products.json"
PRODUCT_UNIQUE_URL = "http://api.vendder.com/bicis.lahsen.cl/products/sku/" # + id.json
EDIT_PRODUCTS_URL = URI('http://api.vendder.com/bicis.lahsen.cl/products/edit')
ORDERS_URL = "http://api.vendder.com/bicis.lahsen.cl/orders/paid.json"
#PRODUCTS_URL = "http://api.localhost/demostore.localhost/products.json"
#PRODUCT_UNIQUE_URL = "http://api.localhost/demostore.localhost/products/sku/" # + id.json
#EDIT_PRODUCTS_URL = URI('http://api.localhost/demostore.localhost/products/edit')
#ORDERS_URL = "http://api.localhost/demostore.localhost/orders/paid.json"
$products = nil

def get_api_data(uri)
  begin
    web_contents  = open(uri,:read_timeout => 300) {|f| f.read }
  rescue RuntimeError => bang
    p "!Rescuing!"
    p bang
  end

  p "Parsing...."                                                                             #products = JSON.parse(web_contents.gsub('\"', '"')) #=> {"a"=>1, "b"=>[0, 1]}
  JSON.parse(web_contents) #=> {"a"=>1, "b"=>[0, 1]}
end

get '/' do

  #ORDENS
  csv_files = Dir['tmp/orders_*']
  csv_files_sorted = csv_files.sort_by {|filename| File.mtime(filename) }
  @csv_files = csv_files_sorted.map{ |file| file.gsub("tmp/","")}
  @csv_files = @csv_files.reverse

  #PRODUCTOS
  if $products.nil?
    p "Loading products from #{PRODUCTS_URL}"
    $products = get_api_data(PRODUCTS_URL)
    p "Products fetched:#{$products.count}"
    session['products'] = "loaded"
  end
  $products

  erb :index
end

post '/products_edit' do
  unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    session['error'] = "No hay archivo!"
    redirect "/"
  end

  $products = nil #so it gets the new updated files.

  STDERR.puts "Uploading file, original name #{name.inspect}"
  products_array = nil
  while blk = tmpfile.read(65536)
    products_array = CSV.parse(blk)
    #STDERR.puts blk.inspect
  end

  products_array.each do |product|
    sku,price,qty = nil,nil,nil
    if product.size > 5
      session['error'] = "Formato Invalido (#{product})"
      redirect "/"
    end
    sku = product[1] + "-" + product[2]
    price = product[3]
    stock = product[4]
    sku_product = get_api_data(PRODUCT_UNIQUE_URL + "#{sku}.json")
    id_by_sku = nil
    id_by_sku = sku_product[0]["product"]["id"] if sku_product && sku_product[0] && sku_product[0]["product"] && sku_product[0]["product"]["id"]# 0 because let's assume all SKU's are unique
    if id_by_sku.nil?
      session['error'] = "SKU:#{sku} no corresponde a producto!"
      redirect "/"
    end
    product_to_edit = nil
    if sku_product[0]["product"]["options"].empty?
      product_to_edit = {"id" => id_by_sku, "price" => price, "stock" => stock}.to_json
    else
      product_to_edit = {"id" => id_by_sku, "options" => [{"values" =>[{"properties" => [{"price" => price, "sku" => sku,"stock" => stock, "stock_unlimited" => false}]}]}] }.to_json
    end
    res = Net::HTTP.post_form(EDIT_PRODUCTS_URL, 'product' => product_to_edit)
    if res.body != "OK"
      session['error'] = "ERROR (#{res.body}) : con SKU:#{sku}"
      redirect "/"
    end
  end
  $products = nil #force refresh list
  session['error'] = "Productos Editados!"
  redirect "/"
end

post "/sign-in" do
  if params[:username] == "lahsen20" && params[:password] == "deciembre24"
    session['logged'] = true
  else
    session['logged'] = false
  end
  redirect "/"
end

get "/sign-out" do
  session['logged'] = false
  redirect "/"
end

get '/new' do
  "Hello world, it's #{Time.now} at the server!"


  p "Loading orders from #{ORDERS_URL}"
  begin
    web_contents  = open(ORDERS_URL,:read_timeout => 300) {|f| p f.read }
  rescue RuntimeError => bang
    p "!Rescuing!"
    p bang
  end
  p "Parsing orders...."
  orders = JSON.parse(web_contents.gsub('\"', '"')) #=> {"a"=>1, "b"=>[0, 1]}

  p "Orders fetched:#{orders.count}"
  csv_string = CSV.generate do |csv|
    i = 1
    orders.each do |order|
      next if order["order"]["status"] == "Abandoned" or order["order"]["status"].nil?

      payment_information, additional_information = order["order"]["payment_information"], order["order"]["additional_information"]
      tarjeta, rut_clean,comuna_clean,comuna_fact_clean,email_fact_clean,tlf_fact_clean,rut_fact_clean,webpay_id_clean = nil, nil, nil, nil

      if payment_information
        array = payment_information.split(",")
        if !array.find_all{|item| item.include?("Tarjeta de Credito") }.empty?
          tarjeta = "TARJETA DE CREDITO"
        end
        if webpay_id = array.find_all{|item| item.include?("Orden Webpay") }
          webpay_id_clean = webpay_id[0].split(":")[1].gsub(/\s+/, "") if webpay_id[0] && webpay_id[0].split(":") && webpay_id[0].split(":")[1]
        end
      end

      if additional_information
        array = additional_information.split(",")
        if rut = array.find_all{|item| item.include?("RUT") }
          rut_clean = rut[0].split(":")[1] if rut[0]
        end
        if comuna = array.find_all{|item| item.include?("Comuna") }
          comuna_clean = comuna[0].split(":")[1] if comuna[0]
        end
        if comuna_fact = array.find_all{|item| item.include?("ComunaFact") }
          comuna_fact_clean = comuna_fact[0].split(":")[1] if comuna_fact[0]
        end
        if email_fact = array.find_all{|item| item.include?("EmailFact") }
          email_fact_clean = email_fact[0].split(":")[1] if email_fact[0]
        end
        if tlf_fact = array.find_all{|item| item.include?("TelefonoFact") }
          tlf_fact_clean = tlf_fact[0].split(":")[1] if tlf_fact[0]
        end
        if rut_fact = array.find_all{|item| item.include?("RUTFact") }
          rut_fact_clean = rut_fact[0].split(":")[1] if rut_fact[0]
        end
      end

      #to comment later
=begin
      csv << ["Tipo Documento",
              "Order ID Lhasen",
              "Tipo",
              "Data",
              "Forma Pago",
              "RUT Cliente",
              "Nombre Envio",
              "Direccion Envio",
              "Ciudad Envio",
              "Region Envio",
              "Pais Envio",
              "Telefono Envio",
              "Email Envio",
              "Nombre Envio",
              "Direccion Envio",
              "Ciudad Envio",
              "Region Envio",
              "Pais Envio",
              "Valor Subtotal",
              "Valor Envio",
              "Valor Descuento",
              "Valor Total",
              "Order ID Webpay"
      ]
=end
      csv << ["1", #TipoProducto: 1 es Bicicletas, 2 es Fitness y 3 Muebles
              "B", #Tipo Documento
              order["order"]["id"],
              "1", #Tipo
              order["order"]["created_at"],
              tarjeta,
              rut_clean,
              order["order"]["billing_address"]["name"] + " " +  order["order"]["billing_address"]["surname"],
              order["order"]["billing_address"]["address"],
              comuna_fact_clean,
              order["order"]["billing_address"]["city"],
              order["order"]["billing_address"]["region"],
              order["order"]["billing_address"]["country"],
              order["order"]["client"]["phone"],
              order["order"]["client"]["email"],
              rut_fact_clean,
              order["order"]["shipping_address"]["name"] + " " + order["order"]["shipping_address"]["surname"],
              order["order"]["shipping_address"]["address"],
              comuna_clean,
              order["order"]["shipping_address"]["city"],
              order["order"]["shipping_address"]["region"],
              order["order"]["shipping_address"]["country"],
              tlf_fact_clean,
              email_fact_clean,
              order["order"]["discount"],
              order["order"]["shipping"],
              order["order"]["total"],
              webpay_id_clean
      ]
=begin
      csv << ["Tipo Documento",
              "Order ID Lhasen",
              "Tipo",
              "SKU",
              "SKU Color",
              "Descripcion",
              "Cantidad",
              "Precio"
      ]
=end
      order["order"]["products"].each do |product|

        sku, sku_color = nil,nil
        sku_arr = product["product"]["sku"].split("-") if product["product"]["sku"]

        if sku_arr && sku_arr.size == 2
          sku = sku_arr[0] if sku_arr.size == 2
          sku_color = sku_arr[1] if sku_arr.size == 2
        else
          sku = product["product"]["sku"]
        end

        csv << ["1", #TipoProducto: 1 es Bicicletas, 2 es Fitness y 3 Muebles
                "B", #Tipo Documento
                order["order"]["id"],
                "2", #Tipo
                sku,
                sku_color,
                product["product"]["name"],
                product["product"]["qty"],
                product["product"]["price"],
                product["product"]["discount"],
                product["product"]["price"].to_f - product["product"]["discount"].to_f
        ]
      end

      i += 1
    end

  end

  #not work on heroku, use S3
  #p "Creating File:"
  @filename = "orders_" + Time.now.strftime("%Y-%m-%d:%M-%S") + ".csv"
  file_path = settings.tmp_path + "/" + @filename

  #headers "Content-Disposition" => "attachment;filename=#{filename}", "Content-Type" => "application/octet-stream"

  aFile = File.new(file_path, "w")
  #p "Writing File to:"
  #p file_path
  aFile.write(csv_string)
  aFile.close
  session['error'] = "Nuevo archivo #{@filename} creado!"
  redirect '/'
end

get '/serve/:filename'  do
  send_file(settings.tmp_path + "/" + params[:filename]) if params[:filename]
end






