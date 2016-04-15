require 'sinatra'
require 'phaxio'
require 'mail'
require 'pony'
require 'tempfile'
require 'openssl'

if not ENV['PHAXIO_KEY'] or not ENV['PHAXIO_SECRET'] or not ENV['MAILGUN_KEY']
  raise "You must specify your phaxio API keys in PHAXIO_KEY and PHAXIO_SECRET"
end

get '/' do
  "MailPhax v1.0 - Visit a mail endpoint: (/mailgun)"
end

get '/mailgun' do
  [400, "Mailgun supported, but callbacks must be POSTs"]
end

$recipientWhitelist = nil

def getRecipientWhitelist()
  if $recipientWhitelist.nil?
    if ENV['RECIPIENT_WHITELIST_FILE']
      $recipientWhitelist = File.read(ENV['RECIPIENT_WHITELIST_FILE']).split
    end
  end
  return $recipientWhitelist
end

$senderWhitelist = nil

def getSenderWhitelist()
  if $senderWhitelist.nil?
    if ENV['SENDER_WHITELIST_FILE']
      $senderWhitelist = File.read(ENV['SENDER_WHITELIST_FILE']).split
    end
  end
  return $senderWhitelist
end

def verifyMailgun(apiKey, token, timestamp, signature)
  calculatedSignature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new(), apiKey, [timestamp, token].join())
  signature == calculatedSignature
end

mailgunTokenCache = []

post '/mailgun' do
  mailgunTokenCacheMaxLength = 50
  timestampThreshold = 30.0

  sender = params['sender']
  if not sender
    return logAndResponse(400, "Must include a sender", logger)
  end

  senderWhitelist = getSenderWhitelist()
  if not senderWhitelist.nil? and not senderWhitelist.include? sender
    return logAndResponse(401, "sender blocked", logger)
  end

  recipient = params['recipient']
  if not recipient
    return logAndResponse(400, "Must include a recipient", logger)
  end

  recipientWhitelist = getRecipientWhitelist()
  if not recipientWhitelist.nil? and not recipientWhitelist.include? recipient
    return logAndResponse(401, "recipient blocked", logger)
  end

  token = params['token']
  if not token
    return logAndResponse(400, "Must include a token", logger)
  end

  signature = params['signature']
  if not signature
    return logAndResponse(400, "Must include a signature", logger)
  end

  timestamp = params['timestamp']
  if not timestamp
    return logAndResponse(400, "Must include a timestamp", logger)
  end

  if mailgunTokenCache.include?(token)
    return logAndResponse(400, "duplicate token", logger)
  end

  mailgunTokenCache.push(token)
  while mailgunTokenCache.length() > mailgunTokenCacheMaxLength
    mailgunTokenCache.pop()
  end

  timestampSeconds = timestamp.to_f
  nowSeconds = Time.now().to_f
  if (timestampSeconds - nowSeconds).abs() > timestampThreshold
    return logAndResponse(400, "timestamp unsafe", logger)
  end

  if not verifyMailgun(ENV['MAILGUN_KEY'], token, timestamp, signature)
    return logAndResponse(400, "signature does not verify", logger)
  end

  attachmentFiles = []

  attachmentCount = params['attachment-count'].to_i
  i = 1
  while i <= attachmentCount do
    tFile = Tempfile.new(params["attachment-#{i}"][:filename])
    data = params["attachment-#{i}"][:tempfile].read()
    tFile.write(data)
    tFile.close()

    attachmentFiles.push(tFile)

    i += 1
  end

  if params['body-plain']
    tFile = Tempfile.new('email-body')
    data = params['body-plain']
    tFile.write(data)
    tFile.close()

    attachmentFiles.push(tFile)
  end

  sendFax(sender, recipient, attachmentFiles)

  attachmentFiles.each do |attachmentFile|
    begin
      attachmentFile.unlink()
    rescue
      # do nothing
    end
  end

  [200, "OK"]
end

def logAndResponse(responseCode, message, logger)
  logger.info(message)
  return [responseCode, message]
end

def sendFax(fromEmail, toEmail, attachmentFiles)
  Phaxio.config do |config|
    config.api_key = ENV["PHAXIO_KEY"]
    config.api_secret = ENV["PHAXIO_SECRET"]
  end

  number = Mail::Address.new(toEmail).local

  options = {to: number, callback_url: "mailto:#{fromEmail}" }

  attachmentFiles.each_index do |idx|
    options["filename[#{idx}]"] = attachmentFiles[idx].path
  end

  logger.info("#{fromEmail} is attempting to send #{attachmentFiles.length} files to #{number}...")
  result = Phaxio.send_fax(options)
  result = JSON.parse(result.body)

  if result['success']
    logger.info("Fax queued up successfully: ID #" + result['data']['faxId'].to_s)
  else
    logger.warn("Problem submitting fax: " + result['message'])

    if ENV['SMTP_HOST']
      #send mail back to the user telling them there was a problem

      Pony.mail(
        :to => fromEmail,
        :from => (ENV['SMTP_FROM'] || 'mailphax@example.com'),
        :subject => 'Mailfax: There was a problem sending your fax',
        :body => "There was a problem faxing your #{attachmentFiles.length} files to #{number}: " + result['message'],
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