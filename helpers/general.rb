helpers do

  def get_api_data(url, params = {})
    begin
      url_auth = url_auth(url, session['login'], session['token'], params)
      result  = open(url_auth, :read_timeout => 300) {|f| f.read }
    rescue RuntimeError => bang
      logger.error "!Rescuing!" + bang.to_s
    end
    JSON.parse(result)
  end

  def put_api_data(url, params, login, token)
    url_auth = url_auth(url,login,token)
    res = REST.put(url_auth, params)
    if res.code == "200"
      [true, res.message]
    else
      [false, res.message]
    end
  end

  def post_api_data(url, params, login, token)
    url_auth = url_auth(url,login,token)
    res = REST.post(url_auth, params)
    if res.code == "200"
      [true, res.message]
    else
      [false, res.message]
    end
  end

  def delete_api_data(url, login, token)
    url_auth = url_auth(url,login, token)
    res = REST.delete(url_auth)
    if res.code == "200"
      [true, res.message]
    else
      [false, res.message]
    end
  end

  def url_auth(url, login, token, params = {})
    uri = Addressable::URI.parse(url)
    uri.query_values = {:login => login.to_s, :authtoken => token.to_s}
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