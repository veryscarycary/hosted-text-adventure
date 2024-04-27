require 'rack'
require 'erb'
require 'faye/websocket'
require 'json'
include Rack

def erb(template)
  path = File.expand_path("#{template}")
  ERB.new(File.read(path)).result(binding)
end

App = Rack::Builder.new {
  # Connect to the Ruby process container
  ruby_process_socket = TCPSocket.new('localhost', 3001)
  # use(Rack::Static, urls: ["/recording"], root: 'recording')

  map('/socket') do
    run(->env{
      puts env
      if Faye::WebSocket.websocket?(env)
        puts "WebSockets connection opened..."
        # @call_data = []
        ws = Faye::WebSocket.new(env)
        puts "Websocket initialized"

        ws.on :message do |event|
          puts "Sending message!"
          # Send message to Ruby process
          ruby_process_socket.puts(event.data)

          # Receive response from Ruby process
          response = ruby_process_socket.gets.chomp
          ws.send(response)
            # ws.send(event.data)
          # end
        end

        ws.on :close do |event|
          puts 'WebSocket connection closed...'
          run(->env {
            [ 302, {'Location' =>'/'}, [[erb("views/index.html.erb")]] ]
          })
        end

        puts "WebSocket sending rack response"
        ws.rack_response
      end
    })
  end

  map('/') do
    if File.exist?('recording.wav')
      @call_status = 'Audio Loaded!'
      @file = 'recording.wav'
    end
    run(->env{
      [200, { 'content-type' => 'text/html'}, [erb("views/index.html.erb")]]})
  end

}
