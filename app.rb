require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'docker'

require_relative 'extensions/systemwatch'

configure do
  set :public_folder, __dir__ + '/public'
  set :views, __dir__ + '/views'

  set :allow_origin, :any
  set :allow_methods, [:get, :options]
  set :expose_headers, ['Content-Type']

  set :API_TOKEN, ENV['API_TOKEN'] || 'default_token' # Set a default token for testing
end

before '/api/*' do
  content_type :json

  if settings.environment == :development
    puts "Development mode: Skipping token validation"
    next
  end

  token = request.env['HTTP_X_API_TOKEN']

  unless token && token == settings.API_TOKEN
    halt 401, { error: 'No valid token found' }.to_json
  end
end

get '/favicon.ico' do
  204
end

get '/api/system' do
  t = SystemWatch
  {
    cpu_usage: t.cpu_usage,
    ram_usage: t.ram_usage
  }.to_json
end

get '/api/time' do
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
  return_hash.to_json
end

get '/api/dockerstats' do
  # Der Benutzer, unter dem die Sinatra-App läuft, muss Zugriff auf den Docker-Socket /var/run/docker.sock haben.
  # Alternativ muss Sinatra als root oder in der docker-Gruppe laufen
  begin
    containers = Docker::Container.all
    stats = containers.map do |container|
      # Holt einmaliges Snapshot-Ergebnis (stream: false verhindert kontinuierliche Ausgabe)
      raw_stats = container.stats(stream: false)

      # CPU-Berechnung, da Docker nur rohe Ticks, Prozent muss berechnet werden
      cpu_delta = raw_stats['cpu_stats']['cpu_usage']['total_usage'] - raw_stats['precpu_stats']['cpu_usage']['total_usage']
      system_delta = raw_stats['cpu_stats']['system_cpu_usage'] - raw_stats['precpu_stats']['system_cpu_usage']
      cpu_percentage = 0.0
      if system_delta > 0 && cpu_delta > 0
        # Anzahl der CPU-Kerne berücksichtigen, falls im Payload vorhanden
        online_cpus = raw_stats['cpu_stats']['online_cpus'] || 1
        cpu_percentage = ((cpu_delta.to_f / system_delta.to_f) * online_cpus * 100.0).round(2)
      end

      # RAM-Berechnung
      memory_usage = (raw_stats['memory_stats']['usage'] / 1024.0 / 1024.0).round(2) # in MB
      memory_limit = (raw_stats['memory_stats']['limit'] / 1024.0 / 1024.0).round(2) # in MB

      {
        id: container.id,
        name: container.info['Names'].first.gsub('/', ''), # Entfernt führenden Slash
        cpu_percentage: cpu_percentage,
        memory_usage: memory_usage,
        memory_limit: memory_limit,
        status: container.info['State']
      }
    end

    stats.to_json

  rescue StandardError => e
    halt 500, { error: "Error in docker stats: #{e.message}" }.to_json
  end
end
