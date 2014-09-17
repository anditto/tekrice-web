require 'sinatra'
require 'json'
require 'net/http'

set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  erb :main
end

get '/dashboard' do
  no_data = {"data" => [{"value" => "N/A"}]}
  dist_api_url  = "http://128.199.191.249/reading/node_2/distance"
  humid_api_url = "http://128.199.191.249/reading/node_2/humidity"
  temp_api_url  = "http://128.199.191.249/reading/node_2/temperature"

  dist_resp   = Net::HTTP.get_response( URI.parse(dist_api_url) )
  dist_result = JSON.parse(dist_resp.body)
  @dist = (!dist_result.nil? && !dist_result["data"].empty? && dist_result["errors"].empty?) ? dist_result : no_data

  humid_resp   = Net::HTTP.get_response( URI.parse(humid_api_url) )
  humid_result = JSON.parse(humid_resp.body)
  @humid= (!humid_result.nil? && !humid_result["data"].empty? && humid_result["errors"].empty?) ? humid_result : no_data

  temp_resp   = Net::HTTP.get_response( URI.parse(temp_api_url) )
  temp_result = JSON.parse(temp_resp.body)
  @temp = (!temp_result.nil? && !temp_result["data"].empty? && temp_result["errors"].empty?) ? temp_result : no_data

  erb :dashboard, locals:{ dist:@dist["data"][0]["value"], humid:@humid["data"][0]["value"], temp:@temp["data"][0]["value"] }
end

get '/dashboard/nodes' do
  erb :nodes
end

get '/dashboard/nodes/:uuid' do
  # Placeholder for all node data
  #
  #api_url = "http://128.199.191.249/nodes/all"
  no_data = {"data" => [{"value" => "N/A"}]}
  
  dist_api_url  = "http://128.199.191.249/reading/node_#{params[:uuid].to_s}/distance"
  humid_api_url = "http://128.199.191.249/reading/node_#{params[:uuid]}/humidity"
  temp_api_url  = "http://128.199.191.249/reading/node_#{params[:uuid]}/temperature"

  dist_resp   = Net::HTTP.get_response( URI.parse(dist_api_url) )
  dist_result = JSON.parse(dist_resp.body)
  @dist = (!dist_result.nil? && !dist_result["data"].empty? && dist_result["errors"].empty?) ? dist_result : no_data

  humid_resp   = Net::HTTP.get_response( URI.parse(humid_api_url) )
  humid_result = JSON.parse(humid_resp.body)
  @humid= (!humid_result.nil? && !humid_result["data"].empty? && humid_result["errors"].empty?) ? humid_result : no_data

  temp_resp   = Net::HTTP.get_response( URI.parse(temp_api_url) )
  temp_result = JSON.parse(temp_resp.body)
  @temp = (!temp_result.nil? && !temp_result["data"].empty? && temp_result["errors"].empty?) ? temp_result : no_data

  erb :nodedetail, locals:{ id:params[:uuid], dist:@dist["data"][0]["value"], humid:@humid["data"][0]["value"], temp:@temp["data"][0]["value"] }
end

get '/dashboard/settings' do
  erb :settings
end

get '/dashboard/map' do
  erb :googlemap
end

get '/test/test.json' do
  data = { :location => "here", :data => "test data" }
  response_data = data.to_json
end

get '/test/mapbox' do
  test = "jojojojo"
  erb :mapbox, locals:{foo: test}
end

helpers do
  def partial template
    erb template, layout:false
  end
end
