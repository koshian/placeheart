$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'dnssd'
require 'json'
require 'uri'
require 'net/http'

class Placeheart
  VERSION = '0.0.1'
  SERVICE = "_placeheart._tcp"

  def initialize
    @server = self.service_search
    sleep 3
  end

  def service_search
    servers = {}
    server = {}

    service = DNSSD.browse(SERVICE) do |reply|
      servers[reply.name] ||= reply
    end
    sleep 3

    servers.each { |string,obj| 
      name, port = string.split ":" 
      DNSSD.resolve(obj.name, obj.type, obj.domain) do |r|
        server[:host] = r.target
        server[:port] = r.port
      end
    }
    service.stop
    server
  end

  def get_json
    time =  Time.now.tv_sec
    url = "http://#{@server[:host]}:#{@server[:port]}/api/loc?t=#{time}&fmt=validjson"
    Net::HTTP.get_response(URI.parse(url)).body
  end

  def json
    JSON.parse(self.get_json)
  end

  def google_maps_uri
    json = self.json
    sprintf('http://maps.google.com/maps?q=%s', "#{json[0]},#{json[1]}");
  end
end
