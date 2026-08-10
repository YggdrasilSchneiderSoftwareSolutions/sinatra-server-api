require 'sinatra'
require 'sinatra/cross_origin'
require 'json'

require_relative 'extensions/systemwatch'

configure do
  set :public_folder, __dir__ + '/public'
  set :views, __dir__ + '/views'

  set :allow_origin, :any
  set :allow_methods, [:get, :post, :options]
  set :allow_credentials, true
  set :max_age, "1728000"
  set :expose_headers, ['Content-Type']
end

helpers do
  def token_valid?
    # TODO
    true
  end
end

get '/favicon.ico' do
  204
end

get '/' do
  t = SystemWatch
  "#{t.cpu_usage}% CPU usage, #{t.ram_usage}% RAM usage"
end

get '/api' do
  unless token_valid?
    halt 401, {'Content-Type' => 'text/plain'}, 'No valid token found'
  end
  
  t = Time.now
  return_hash = {
    # ??? :utc_offset => t.
    :timezone => t.zone,
    :day_of_month => t.day,
    :day_of_week => t.wday,
    :day_of_year => t.yday,
    :month => t.month,
    :year => t.year,
    :datetime => t,
    :utc_datetime => t.getutc,
    :unixtime => t.to_i,
    :raw_offset => t.utc_offset
    # TODO Wochentag ausgeben
  }
  json_object = JSON.generate(return_hash)

  [200, { 'Content-Type' => 'application/json' }, json_object]
end