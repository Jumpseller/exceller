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

[Try out the Live version](http://exceller.heroku.com)  

[Jumpseller API Documentation](http://jumpseller.com/support/api)

---

Copyright 2015 ® Jumpseller

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this work except in compliance with the License. You may obtain a copy of
the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations.
