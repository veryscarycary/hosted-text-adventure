require 'rack'
require 'erb'
require 'faye/websocket'
require 'json'
include Rack

TCP_SERVER_ENDPOINT = ENV['TCP_SERVER_ENDPOINT'] || 'text-adventure' # docker allows address to be the container name
TCP_SERVER_CONTAINER_PORT = 3001
DEFAULT_IO_TIMEOUT = 0.3
KEEPALIVE_TIME = 30 # in seconds

def erb(template)
  path = File.expand_path("#{template}")
  ERB.new(File.read(path)).result(binding)
end

# Exits quickly to give response back, but may get cut off
# if response is larger
# def get_quick_tcp_response(tcp_server)
#   response = ""
#   begin
#     loop do
#       chunk = tcp_server.recvmsg_nonblock(10000)
#       response += chunk
#     end
#   rescue IO::WaitReadable, EOFError
#     # No more data available, continue processing
#   end
#   # Receive response from Ruby process
#   puts "response: #{response}"
#   response
# end

# relies on timeout to exit out, in order to get larger responses
# def get_response(tcp_server, timeout = DEFAULT_IO_TIMEOUT)
#   response = ""

#   loop do
#     ready = IO.select([tcp_server], nil, nil, timeout)
#     if ready
#       begin
#         chunk = tcp_server.recv_nonblock(1024)
#         response += chunk
#       rescue IO::WaitReadable, EOFError
#         # No more data available, continue processing
#       end
#     else
#       # Timeout reached
#       puts "Timeout reached. Sending current response"
#       puts "response: #{response}"
#       return response
#     end
#   end
  
#   puts "response: #{response}"
#   response
# end

class Server
  attr_accessor :web_socket_server

  def initialize(env)
    @web_socket_server = Faye::WebSocket.new(env, nil, { ping: KEEPALIVE_TIME })
    puts "WebSockets connection opened and initialized..."
    @tcp_server = TCPSocket.new(TCP_SERVER_ENDPOINT, TCP_SERVER_CONTAINER_PORT)
    puts "TCP Socket connection opened and initialized..."

    send_to_client(receive_from_ruby_process) # immediately send first output from ruby process

    @web_socket_server.on :open do |event|
      p [:open, @web_socket_server.object_id]
    end

    @web_socket_server.on :message do |event|
      puts "Sending message!"
      p [:message, event.data]
      send_to_ruby_process(event.data)
      response = receive_from_ruby_process
      send_to_client(response)
    end

    @web_socket_server.on :close do |event|
      puts 'WebSocket connection closed...'
      puts "Event: #{event}"
      p [:close, @web_socket_server.object_id, event.code, event.reason]
      run(->env {
        [ 302, {'Location' =>'/'}, [[erb("views/index.html.erb")]] ]
      })
    end
  end

  def send_to_client(message)
    @web_socket_server.send(message)
  end

  def send_to_ruby_process(message)
    @tcp_server.puts(message)
  end

  def receive_from_ruby_process(timeout = DEFAULT_IO_TIMEOUT)
    response = ""

    loop do
      ready = IO.select([@tcp_server], nil, nil, timeout)
      if ready
        begin
          chunk = @tcp_server.recv_nonblock(1024)
          response += chunk
        rescue IO::WaitReadable, EOFError
          # No more data available, continue processing
        end
      else
        # Timeout reached
        puts "Timeout reached. Sending current response"
        puts "response: #{response}"
        return response
      end
    end
    
    puts "response: #{response}"
    response
  end
end

App = Rack::Builder.new {  
  use Rack::Static,
  urls: ["/favicon"],
  root: File.expand_path(".")

  map('/socket') do
    run(->env{
      puts env
      if Faye::WebSocket.websocket?(env)
        server = Server.new(env)
        puts "WebSocket sending rack response"
        server.web_socket_server.rack_response      
      end
    })
  end

  map('/') do
    run(->env{
      [200, { 'content-type' => 'text/html'}, [erb("views/index.html.erb")]]})
  end
}
