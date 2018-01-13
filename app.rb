#############################################
# Environment Variable Configuration
# - lists all variables needed for this script to work
#############################################
# TOKEN
#   - Requires an extended access token to read conversation to identify if it is from the help center
#   - Apply for an access token  https://app.intercom.io/developers/_
#   - Read more about access tokens https://developers.intercom.com/reference#personal-access-tokens-1 
# APP_ID
#   - your Intercom app_id that you use in the [Javascript Visitor/Logged out Install](https://docs.intercom.com/install-on-your-product-or-site/quick-install/install-intercom-on-your-website-for-logged-out-visitors) / [Javascript user install](https://docs.intercom.io/install-on-your-product-or-site/install-intercom-on-your-web-app)
# GA_TRACKING_ID
#   - Your Google Analytics Track ID (e.g.UA-ABCDEFGHIJ-K)
# CUSTOM_ATTRIBUTE_NAME
#   - the name of the custom attribute in Intercom to track the customers Google Analytics Unique identifier
#   - e.g. google_analytics_id
#############################################
# For development just rename .env.sample to .env and modify values appropriately
#############################################

require 'sinatra'
require 'json'
require 'active_support/time'
require 'intercom'
require 'nokogiri'
require 'dotenv'
require "net/http"
Dotenv.load

DEBUG = ENV["DEBUG"] || nil
get '/' do
  erb :index
end

post '/' do
  request.body.rewind
  payload_body = request.body.read
  if DEBUG then
    puts "==============================================================="
    puts payload_body
    puts "==============================================================="
  end
  verify_signature(payload_body)
  response = JSON.parse(payload_body)
  if DEBUG then
    puts "Topic Recieved: #{response['topic']}"
  end
  if is_supported_topic(response['topic']) then
    process_webhook(response)
  end
end

def init_intercom
  if @intercom.nil? then
    token = ENV["TOKEN"]
    @intercom = Intercom::Client.new(token: token)
  end
end

def is_supported_topic(topic)
  topic.index("conversation.user.replied") || topic.index("conversation.user.created")
end
def has_google_analytics_id(user_type,intercom_id)
  init_intercom
  puts "Found #{user_type} with id: #{intercom_id}"
  if user_type == "user" then
    user = @intercom.users.find(id: intercom_id)
  else
    user = @intercom.contacts.find(id: intercom_id)
  end
  return user.custom_attributes[ENV["CUSTOM_ATTRIBUTE_NAME"]]
end



def process_webhook(response)
  if DEBUG then
    puts "Process webhook....."
  end

  begin
    user_type = response['data']['item']['user']['type']
    intercom_id = response['data']['item']['user']['id']
    if gid = has_google_analytics_id(user_type,intercom_id) then
      puts "Got a message from a record with a Google Analytics ID. Trigger conversion!"
      trigger_conversion(gid)
    end
  rescue Exception => e 
    if DEBUG then
      puts "Exception!"
      puts e.message
      puts e.backtrace.inspect  
    else
      puts "Exception =("
    end
    return
  end
end

def trigger_conversion(google_analytics_id)
  track_event "Conversation", "Wrote in", "Intercom", 1, google_analytics_id
end

# https://github.com/GoogleCloudPlatform/ruby-docs-samples/blob/master/appengine/analytics/app.rb
def track_event category, action, label, value, client_id
  gaid = ENV["GA_TRACKING_ID"]
  puts "Track #{client_id} in GA: #{gaid}"
  Net::HTTP.post_form URI("http://www.google-analytics.com/collect"),
    v: "1",               # API Version
    tid: gaid,  # Tracking ID / Property ID
    cid: client_id,       # Client ID
    t: "event",           # Event hit type
    ec: category,         # Event category
    ea: action,           # Event action
    el: label,            # Event label
    ev: value             # Event value
end

def verify_signature(payload_body)
  secret = ENV["secret"]
  expected = request.env['HTTP_X_HUB_SIGNATURE']

  if secret.nil? || secret.empty? then
    puts "No secret specified so accept all data"
  elsif expected.nil? || expected.empty? then
    puts "Not signed. Not calculating"
  else

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
    puts "Expected  : #{expected}"
    puts "Calculated: #{signature}"
    if Rack::Utils.secure_compare(signature, expected) then
      puts "   Match"
    else
      puts "   MISMATCH!!!!!!!"
      return halt 500, "Signatures didn't match!"
    end
  end
end
