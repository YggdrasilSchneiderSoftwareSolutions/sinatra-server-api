# Start entweder über rackup -p 4567 (development)
# oder über bundle exec rackup -p 4567 (production)
ENV['API_TOKEN'] = 'api_token'

require './app'
run Sinatra::Application