## Jumpseller - Exceller  
This is an official Jumpseller Ruby mini-application using its v1 API, allowing to edit Products on the fly.

##API Access

To get your API's `login` / `authtoken`, visit your Account Page at your store's Admin Panel (at the top-right corner).

## Usage

    bundle install
    ruby app.rb
    open http://localhost:4567

### Requirements

* ruby 2.1.1
* sinatra
* httparty

### Call examples

Retrieve store's products:

    require 'httparty'
    url = "http://api.localhost/v1/products.json?authtoken=XXX&limit=50&login=XXX&page=1"
    response = HTTParty.get(url)
    puts response.code
    puts response.body

Update a specific product:
    
    require 'httparty'
    require 'json'
    url = "http://api.localhost/v1/products/210719?authtoken=PLXJHTEVJYWNXRVRIBYUEDUUGMUKFSQL&login=demostore"
    HTTParty.put(url,
    { :body => { product: {name: 'my new product name'} }.to_json, 
      :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    })

###More info

[Try](http://exceller.heroku.com) a Live version on Heroku

[API Documentation](http://jumpseller.com/support/api)