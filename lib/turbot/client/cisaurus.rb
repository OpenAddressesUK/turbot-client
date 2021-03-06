require "turbot/client"

class Turbot::Client::Cisaurus

  include Turbot::Helpers

  def initialize(uri)
    require 'rest_client'
    @uri = URI.parse(uri)
  end

  def authenticated_resource(path)
    host = "#{@uri.scheme}://#{@uri.host}"
    host += ":#{@uri.port}" if @uri.port
    RestClient::Resource.new("#{host}#{path}", "", Turbot::Auth.api_key)
  end

  def copy_slug(from, to)
    authenticated_resource("/v1/bots/#{from}/copy/#{to}").post(json_encode("description" => "Forked from #{from}"), :content_type => :json).headers[:location]
  end

  def job_done?(job_location)
    202 != authenticated_resource(job_location).get.code
  end
end
