require 'net/http'

module REST
  def self.get(url)
    uri = URI.parse(url)
    http = Net::HTTP.start(uri.host, uri.port)
    resp = http.send_request('GET', uri.request_uri)
    resp.body
  end

  def self.post(url, data)
    uri = URI.parse(url)
    http = Net::HTTP.start(uri.host, uri.port)
    req = Net::HTTP::Post.new uri.request_uri
    res = http.request(req, data)
  end

  def self.put(url, data)
    uri = URI.parse(url)
    http = Net::HTTP.start(uri.host, uri.port)
    req = Net::HTTP::Put.new uri.request_uri
    res = http.request(req, data)
  end

  def self.delete(url)
    uri = URI.parse(url)
    http = Net::HTTP.start(uri.host, uri.port)
    resp = http.send_request('DELETE', uri.request_uri)
  end

end