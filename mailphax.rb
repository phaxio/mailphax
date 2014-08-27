require 'sinatra'

get '/' do
  "Mailfax v1.0 - Visit a mail endpoint: (/sendgrid, /mandrill, /mailgun)"
end


get '/mandrill' do
  [400, "Mandrill supported, but callbacks must be POSTs"]
end

post '/mandrill' do
  "OK"
end

get '/mailgun' do
  [400, "Mailgun supported, but callbacks must be POSTs"]
end

post '/mailgun' do
  logger.info params
  "OK"
end

get '/sendgrid' do
  [501, "sendgrid not implemented yet"]
end
