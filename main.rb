require 'sinatra'
require 'json'
require 'net/http'
require 'i18n'
require 'i18n/backend/fallbacks'

## SETTINGS

set :public_folder, File.dirname(__FILE__) + '/static'
set :locales, %w[jp en]
set :default_locale, 'en'
set :locale_pattern, /^\/?(#{Regexp.union(settings.locales)})(\/.*)$/

## ROUTES

# Locales
before do
  @locale, request.path_info = $1, $2 if request.path_info =~ settings.locale_pattern
end

# Main Page
get '/?' do
  case locale
  when 'jp'
    erb :main_jp
  when 'en'
    erb :main_en
  else   #DEFAULT
    erb :main_en
  end
end

## Dirty hack just so /en & /jp works. Consequently, /{en,jp}/{en,jp} also works.
get '/en' do
  erb :main_en
end

get '/jp' do
  erb :main_jp
end


# Sensor data visuals
show_sensor_data = lambda do
  site_list   = get_site_list.keys

  case locale
  when 'jp'
    sensor_list = [ "温度", "水位", "湿度", "電池", "雨量", "太陽放射"]
    sensor_unit = { 
      "温度" => "&deg;C", "水位" => "cm",
      "湿度" => "%", "電池" => "%"
    }
    sensor_hash = { 
      "温度" => "ambient temperature", "水位" => "water_level",
      "湿度" => "air humidity", "電池" => "battery_voltage"
    }
  when 'en'
    sensor_list = [ "Temperature", "Water", "Moisture", "Battery", "Rainfall", "Solar radiation"]
    sensor_unit = { 
      "Temperature" => "&deg;C", "Water" => "cm",
      "Moisture" => "%", "Battery" => "%"
    }
    sensor_hash = { 
      "Temperature" => "ambient temperature", "Water" => "water_level",
      "Moisture" => "air humidity", "Battery" => "battery_voltage"
    }
  else  #DEFAULT
  end

  if !sensor_list.include? params[:sensor]
    redirect '/node/' + params[:site] + '/' + params[:uuid]
  end

  @site_data = get_data_for_site(params[:site])

  node_list = get_node_list(@site_data)

  @site_data = JSON.parse(@site_data)

  dataset = [
    { "index"=>"0", "day"=>"月" },
    { "index"=>"1", "day"=>"火" },
    { "index"=>"2", "day"=>"水" },
    { "index"=>"3", "day"=>"木" },
    { "index"=>"4", "day"=>"金" },
    { "index"=>"5", "day"=>"土" },
    { "index"=>"6", "day"=>"日" }
  ]

  @site_data["objects"][0]["nodes"].each do |node|
    if node["id"].to_s == params[:uuid]
      node["sensors"].each do |x|
        if x["alias"] == sensor_hash[ params[:sensor] ]
          @node_data = get_reading_for_node( x["id"] )
          i = 0
          (-7..-1).each do |j|
            #dataset[i]["value"] = (@node_data[j]).round(2)
            # Dummy Data
            dataset[i]["value"] = rand(0..100)
            i+=1
          end
        end
      end
    end
  end

  locals = {
    id:params[:uuid],
    sensor:params[:sensor],
    sensor_unit:sensor_unit[params[:sensor]],
    dataset:dataset.to_json,
    latest_value:dataset[-1]["value"],
    site:params[:site],
    site_list:site_list,
    node_list:node_list,
    sensor_list:sensor_list,
    node_data:@node_data
  }

  case locale
  when 'jp'
    if params[:sensor] == '雨量'
      erb :rainfall_jp, locals:locals
    elsif params[:sensor] == '太陽放射'
      erb :solarradiation_jp, locals:locals
    elsif params[:sensor] == '水位'
      erb :waterlevel_jp, locals:locals
    else
      erb :sensordetail_jp, locals:locals
    end
  when 'en'
    if params[:sensor] == 'Rainfall'
      erb :rainfall_en, locals:locals
    elsif params[:sensor] == 'Solar radiation'
      erb :solarradiation_en, locals:locals
    elsif params[:sensor] == 'Water'
      erb :waterlevel_en, locals:locals
    else
      erb :sensordetail_en, locals:locals
    end
  end
end

get '/node/:site/:uuid/:sensor/?', &show_sensor_data

# Pre-emptive redirect, don't know what to do with it yet
show_site_nodes = lambda do
  #TODO No ideas yet, so will change redirect or make new page
  redirect '/map/' + params[:site]
end

get '/node/:site', &show_site_nodes
get '/node/:site/', &show_site_nodes

# Sensor list for 1 node
show_sensor_list = lambda do
  site_list   = get_site_list.keys
  @site_data = get_data_for_site(params[:site])
  node_list = get_node_list(@site_data)

  case locale
  when 'jp'
    sensor_list = [ "温度", "水位", "湿度", "電池", "雨量", "太陽放射"]

    erb :sensor_list_jp, locals:{
      id:params[:uuid],
      site:params[:site],
      site_list:site_list,
      node_list:node_list,
      sensor_list:sensor_list
    }
  when 'en'
    sensor_list = [ "Temperature", "Water", "Moisture", "Battery", "Rainfall", "Solar radiation"]

    erb :sensor_list_en, locals:{
      id:params[:uuid],
      site:params[:site],
      site_list:site_list,
      node_list:node_list,
      sensor_list:sensor_list
    }
  else   #DEFAULT
    sensor_list = [ "Temperature", "Water", "Moisture", "Battery", "Rainfall", "Solar radiation"]

    erb :sensor_list_en, locals:{
      id:params[:uuid],
      site:params[:site],
      site_list:site_list,
      node_list:node_list,
      sensor_list:sensor_list
    }
  end
end

get '/node/:site/:uuid/?', &show_sensor_list

# Map Data
show_map_data = lambda do
  site_list = get_site_list.keys

  if !(site_list.include?(params[:site]))
    redirect '/map/' + site_list[0]
  end

  @site_data = get_data_for_site(params[:site])

  node_list  = get_node_list(@site_data)

  case locale
  when 'jp'
    erb :map_jp, locals:{ data:@site_data, site:params[:site], site_list:site_list, node_list:node_list }
  when 'en'
    erb :map_en, locals:{ data:@site_data, site:params[:site], site_list:site_list, node_list:node_list }
  else  #DEFAULT
    erb :map_en, locals:{ data:@site_data, site:params[:site], site_list:site_list, node_list:node_list }
  end
end

get '/map/:site/?', &show_map_data

# Default Map
show_default_map = lambda do
  site_list = get_site_list.keys
  redirect '/map/' + site_list[0]
end

get '/map/?', &show_default_map

# List of Sensors
get '/list/:site' do
  @all_data = get_data_for_site(params[:site])

  #TODO remove when real data is available
  @all_data = make_up_dummy_data_for_dataset(@all_data)

  erb :list, locals:{ data:JSON.parse(@all_data), json_data:@all_data, site:params[:site] }
end

# 404 Error page
not_found do
  status 404
  erb :sorry
end


## UNUSED ROUTES

# Dashboard
get '/dashboard' do
  @all_data = get_data_for_site('hackerfarm')

  erb :dashboard, locals:{ data:JSON.parse(@all_data), json_data:@all_data }
end
get '/dashboard/nodes' do
  erb :nodes
end
get '/settings' do
  erb :settings, locals:{ site:"hackerfarm" }
end

# Testimonial page
get '/testimonials' do
  erb :testimonials
end


## HELPERS

helpers do
  def partial template
    erb template, layout:false
  end
end

helpers do
  def locale
    @locale || settings.default_locale
  end
end

## TODO Move to a separate file
## PRIVATE HELPER FUNCTIONS

private

def get_data_for_site(site)
  cache_file   = File.join("cache", site)
  site_id_hash = get_site_list

  if !File.exist?(cache_file) || (File.mtime(cache_file) < (Time.now - 60*60))
    api_link = "http://satoyamacloud.com/site/" + site_id_hash[site].to_s
    #api_link = "http://128.199.120.30/site/" + site_id_hash[site].to_s
    #TODO Currently gives out SocketError
    #all_data_call = Net::HTTP.get_response(URI.parse( api_link ))
    
    # Inserts new data into cache file
    #if all_data_call.code == "200"
    #  # Clean up data for null values, misordered keys, etc.
    #  @all_data = cleanup_sitedata(JSON.parse(all_data_call.body))
    #  #@all_data = JSON.parse(all_data_call.body)

    #  File.open(cache_file, "w"){ |f| f << @all_data.to_json }
    #  @all_data = File.read(cache_file)
    #else
      if File.exist?(cache_file)
        @all_data = File.read(cache_file)
      else
        @all_data = test_data
      end
    #end
  else
    @all_data = File.read(cache_file)
  end

  return @all_data
end

def cleanup_sitedata(data)
  # Desired data structure -> Look at Dummy Data
  clean_data =
  {
    "errors"  => "",
    "objects" => [],
    "query"   => ""
  }

  clean_data["errors"] = (!data["errors"].nil? ? data["errors"] : "")
  clean_data["query"]  = (!data["query"].nil? ? data["query"] : "")

  # OBJECTS
  data["objects"].each_with_index do |object, i|
    clean_object = {}
    clean_object["alias"] = (!object["alias"].nil? ? object["alias"] : "object_alias#{i}")
    clean_object["id"]    = (!object["id"].nil? ? object["alias"] : "#{i}")

    # NODES
    clean_object["nodes"] = []
    if !object["nodes"].nil? 
      object["nodes"].each_with_index do |node, j|
        clean_node = {}
        clean_node["alias"] = (!node["alias"].nil? ? node["alias"] : "node_alias#{j}")
        clean_node["id"]    = (!node["id"].nil? ? node["id"] : "#{j}")
        clean_node["latitude"]  = (!node["latitude"].nil? ? node["latitude"] : 35.646261)
        clean_node["longitude"] = (!node["longitude"].nil? ? node["longitude"] : 139.703749)

        # SENSORS
        clean_node["sensors"] = []
        if !node["sensors"].nil?
          node["sensors"].each_with_index do |sensor, k|
            clean_sensor = {}
            clean_sensor["alias"] = (!sensor["alias"].nil? ? sensor["alias"] : "sensor_alias#{k}")
            clean_sensor["id"]    = (!sensor["id"].nil? ? sensor["id"] : "#{k}")

            # READINGS
            clean_sensor["latest_reading"] = {}
            if sensor.has_key?("latest_reading") && !sensor["latest_reading"].nil?
              clean_reading = {}
              clean_reading["id"]        = (!sensor["latest_reading"]["id"].nil? ? sensor["latest_reading"]["id"] : 1)
              clean_reading["sensor_id"] = (!sensor["latest_reading"]["sensor_id"].nil? ? sensor["latest_reading"]["sensor_id"] : 1)
              clean_reading["timestamp"] = (!sensor["latest_reading"]["timestamp"].nil? ? sensor["latest_reading"]["timestamp"] : Time.now.iso8601)
              clean_reading["value"]     = (!sensor["latest_reading"]["value"].nil? ? sensor["latest_reading"]["value"] : 0)

              # READING - SENSOR
              clean_reading["sensor"] = []
              if sensor["latest_reading"].has_key?("sensor") && !sensor["latest_reading"]["sensor"].nil?
                sensor["latest_reading"]["sensor"].each_with_index do |reading_sensor, m|
                  clean_reading_sensor = {}
                  clean_reading_sensor["alias"] = (!reading_sensor["alias"].nil? ? reading_sensor["alias"] : "reading_sensor_alias#{m}")
                  clean_reading_sensor["id"]    = (!reading_sensor["id"].nil? ? reading_sensor["id"] : "#{m}")

                  #Insert clean reading_sensor data
                  clean_reading["sensor"] << clean_reading_sensor
                end
              else
                clean_reading["sensor"] = [{
                  "alias" => "test",
                  "id"    => 1
                }]
              end
              ### READING-SENSOR

              #Insert clean latest reading data
              clean_sensor["latest_reading"] = clean_reading
            else
              clean_sensor["latest_reading"] = {
                "id"        => 1,
                "sensor_id" => 1,
                "timestamp" => Time.now.iso8601,
                "value"     => 0,
                "sensor"    => [
                  {
                    "alias" => "test",
                    "id"    => 1
                  }
                ]
              }
            end
            ### READINGS

            clean_node["sensors"] << clean_sensor
          end
        else
          clean_node["sensors"] = [
            "alias" => "test",
            "id"    => 1,
            "latest_reading" => {
              "id"        => 1,
              "sensor_id" => 1,
              "timestamp" => Time.now.iso8601,
              "value"     => 0,
              "sensor"    => [
                {
                  "alias" => "test",
                  "id"    => 1
                }
              ]
            }
          ]
        end

        #Insert clean node data
        clean_object["nodes"] << clean_node
      end
    else
      clean_object["nodes"] = [{
        "sensors" => [
          "alias" => "test",
          "id"    => 1,
          "latest_reading" => {
            "id"        => 1,
            "sensor_id" => 1,
            "timestamp" => Time.now.iso8601,
            "value"     => 0,
            "sensor"    => [
              {
                "alias" => "test",
                "id"    => 1
              }
            ]
          }
        ]
      }]
    end

    # Insert data
    clean_data["objects"] << clean_object
  end

  return clean_data
end

def make_up_dummy_data_for_dataset(data)
  parsed_data = JSON.parse(data)
  parsed_data["objects"][0]["nodes"].each_with_index do |node, node_index|
    node["sensors"].each_with_index do |reading, sensor_index|
      if reading["latest_reading"].nil?
        parsed_data["objects"][0]["nodes"][node_index]["sensors"][sensor_index]["latest_reading"] = 10 + rand(30)
      end
    end
  end

  return parsed_data.to_json
end

def get_node_list(data)
  node_list   = Hash.new
  #parsed_data = eval(data)
  parsed_data = JSON.parse(data)
  null_alias  = parsed_data["objects"][0]["alias"].downcase.gsub(" ", "")
  parsed_data["objects"][0]["nodes"].each_with_index do |node, index|
    if (node["alias"]) 
      node_list[node["id"]] = node["alias"]
    else
      node_list[node["id"]] = (null_alias + index.to_s)
    end
  end

  return node_list
end

def get_site_list
  site_hash = {}

  #TODO Currently gives out SocketError
  api_link = "http://satoyamacloud.com/sites"
  #api_link = "http://128.199.120.30/sites"
  #all_data_call = Net::HTTP.get_response(URI( api_link ))

  #case all_data_call
  #when Net::HTTPSuccess then
  #  all_data = JSON.parse(all_data_call.body)
  #  all_data["objects"].each do |site|
  #    if !site["alias"].nil?
  #      site_hash[ site["alias"].downcase.gsub(" ", "") ] = site["id"]
  #    else
  #      # Placeholder
  #      site_hash[ site["id"] ] = site["id"]
  #    end
  #  end
  #else
    #Use dummy data
    site_hash = {
      "hackerfarm"    => 1,
      "digitalgarage" => 2,
      "dgkamakura"    => 3,
      "halfdan_home"  => 4,
      "sanfrancisco"  => 5
    }
  #end

  return site_hash
end

def get_reading_for_node(node_id)
  api_link = "http://satoyamacloud.com/readings?sensor_id=" + node_id.to_s
  #api_link = "http://128.199.120.30/readings?sensor_id=" + node_id.to_s
  #all_data_call = Net::HTTP.get_response(URI.parse( api_link ))

  #if all_data_call.code == "200"
  #  all_data = JSON.parse(all_data_call.body)
  #else
    # Dummy data
    file = File.join("cache", "halfdan_home")
    all_data = JSON.parse(File.read(file))
  #end

  #sensor_alias = all_data["objects"][0]["sensor"][0]["alias"]
  value = []

  #all_data["objects"].each do |reading|
  #  value << reading["value"]
  #end

  # Dummy data
  value = [ rand(0..35), rand(40..60), rand(50..70), rand(0..100)]

  return value
end
