require 'httparty'
helpers do

  def get_api_data(url, params = {}, parse_json = false)
    res = HTTParty.get(url_auth(url))
    message = parse_json ? JSON.parse(res.body) : res.body
    res.code == "200" ? [true, message] : [false, message]
  end

  # soon to deprecate
  def get_api_data2(url)
    url_auth = url_auth(url)
    res = REST.get(url_auth)
    if res.code == "200"
      [true, res.body]
    else
      [false, res.body]
    end
  end

  def put_api_data(url, params)
    res = HTTParty.put(url_auth(url), { 
      body: params.to_json,
      login: params[:login],
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    })
    res.code == "200" ? [true, res.body] : [false, res.body]
  end

  def delete_api_data(url)
    url_auth = url_auth(url)
    res = REST.delete(url_auth)
    if res.code == "200"
      [true, res.message]
    else
      [false, res.message]
    end
  end

  # adds the login and token as query strings.
  def url_auth(url, params = {})
    uri = Addressable::URI.parse(url)
    uri.query_values = {:login => session['login'].to_s, :authtoken => session['token'].to_s}
    uri.query_values = uri.query_values.merge( params )
    uri.to_s
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def has_variants?(product)
    product["product"]["variants"] && !product["product"]["variants"].empty?
  end

  def url_admin
    "https://#{session['login']}.jumpseller.com/admin"
  end

end