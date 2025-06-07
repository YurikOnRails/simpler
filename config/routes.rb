Simpler.application.routes do
  get '/tests', 'tests#index'
  get '/tests/plain', 'tests#plain'
  get '/tests/json', 'tests#json'
  get '/tests/html', 'tests#html'
  get '/tests/xml', 'tests#xml'
  get '/tests/:id', 'tests#show'
  post '/tests/status', 'tests#custom_status'
end
