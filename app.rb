require 'rack'
require 'erb'
require 'faye/websocket'
require 'json'
include Rack

def erb(template)
  path = File.expand_path("#{template}")
  ERB.new(File.read(path)).result(binding)
end

def get_response_from_tcp_server(tcp_server)
  response = ""
  begin
    loop do
      chunk = tcp_server.recv_nonblock(1024)
      response += chunk
    end
  rescue IO::WaitReadable, EOFError
    # No more data available, continue processing
  end
  # Receive response from Ruby process
  # response = ruby_process_socket.gets.chomp
  puts "response: #{response}"
  response
end

App = Rack::Builder.new {
  # Connect to the Ruby process container
  # use(Rack::Static, urls: ["/recording"], root: 'recording')
  
  map('/socket') do
    run(->env{
      puts env
      if Faye::WebSocket.websocket?(env)
        puts "WebSockets connection opened..."
        ws = Faye::WebSocket.new(env)
        ruby_process_socket = TCPSocket.new('tcp-text-adventure', 3001)
        puts "Websocket initialized"

        ws.on :message do |event|
          puts "Sending message!"
          # Send message to Ruby process
          ruby_process_socket.puts(event.data)
          puts "Event data: #{event.data}"

          # response = ""
          # i = 0
          # while line = ruby_process_socket.gets.chomp
          #   break if i > 1000
          #   puts line
          #   puts i
          #   response += "#{line}\n"
          #   i += 1
          # end

          response = get_response_from_tcp_server(ruby_process_socket)
          puts "response: #{response}"
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
