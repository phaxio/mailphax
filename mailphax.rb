require 'sinatra'
require 'phaxio'
require 'mail'
require 'pony'

if not ENV['PHAXIO_KEY'] or not ENV['PHAXIO_SECRET']
  raise "You must specify your phaxio API keys in PHAXIO_KEY and PHAXIO_SECRET"
end

get '/' do
  "Mailfax v1.0 - Visit a mail endpoint: (/sendgrid, /mandrill, /mailgun)"
end


get '/mandrill' do
  [501, "mandrill not implemented yet"]
end

post '/mandrill' do
  [501, "mandrill not implemented yet"]
end

get '/mailgun' do
  [400, "Mailgun supported, but callbacks must be POSTs"]
end

post '/mailgun' do

  if not params['sender']
    return [400, "Must include a sender"]
  elsif not params['recipient']
    return [400, "Must include a recipient"]
  end

  files = []
  attachmentCount = params['attachment-count'].to_i

  i = 1
  while i <= attachmentCount do
    #add the file to the hash
    outputFile = "/tmp/#{Time.now.to_i}-#{rand(200)}-" + params["attachment-#{i}"][:filename]

    File.open(outputFile, "w") do |f|
      f.write(params["attachment-#{i}"][:tempfile].read)
    end

    files.push(outputFile)

    i += 1
  end

  sendFax(params['sender'], params['recipient'],files)
  "OK"
end

get '/sendgrid' do
  [501, "sendgrid not implemented yet"]
end

def sendFax(fromEmail, toEmail, filenames)
  Phaxio.config do |config|
    config.api_key = ENV["PHAXIO_KEY"]
    config.api_secret = ENV["PHAXIO_SECRET"]
  end

  number = Mail::Address.new(toEmail).local

  options = {to: number, callback_url: "mailto:#{fromEmail}" }

  filenames.each_index do |idx|
    options["filename[#{idx}]"] = File.new(filenames[idx])
  end

  logger.info "#{fromEmail} is attempting to send #{filenames.length} files to #{number}..."
  result = Phaxio.send_fax(options)
  result = JSON.parse result.body

  if result['success']
    logger.info "Fax queued up successfully: ID #" + result['data']['faxId'].to_s
  else
    logger.warn "Problem submitting fax: " + result['message']

    if ENV['SMTP_HOST']
      #send mail back to the user telling them there was a problem

      Pony.mail(
        :to => fromEmail,
        :from => (ENV['SMTP_FROM'] || 'mailphax@example.com'),
        :subject => 'Mailfax: There was a problem sending your fax',
        :body => "There was a problem faxing your #{filenames.length} files to #{number}: " + result['message'],
        :via => :smtp,
        :via_options => {
          :address                => ENV['SMTP_HOST'],
          :port                   => (ENV['SMTP_PORT'] || 25),
          :enable_starttls_auto   => ENV['SMTP_TLS'],
          :user_name              => ENV['SMTP_USER'],
          :password               => ENV['SMTP_PASSWORD'],
          :authentication         => :login
        }
      )
    end
  end
end