# Copyright © Mapotempo, 2019
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require './api/v01/api_base'

module Api
  module V01
    class Geocoder < APIBase
      @@result_types = {'city' => 'city', 'street' => 'street', 'locality' => 'street', 'intersection' => 'intersection', 'house' => 'house', 'poi' => 'house'}.freeze
      # Allow the class to use text/plain render while we use a default_format :json trough the API
      content_type :txt, "text/plain"

      helpers do
        # Never trust parameters from the scary internet, only allow the white list through.
        def destination_params
          p = ActionController::Parameters.new(params)
          p = p[:destination] if p.key?(:destination)
          p.permit(:q, :json_callback)
        end

        def geocode(q, country, limit = 10, lat = nil, lng = nil)
          begin
            result = RestClient.get(ENV['GEOCODER_URL'], params: {
              api_key: ENV['GEOCODER_API_KEY'] || 'demo',
              limit: limit,
              query: q,
              country: country
            })
          rescue
            raise
          end
          data = JSON.parse(result)
          features = data['features']
          features.collect{ |feature|
            parse_geojson_feature(feature)
          }
        end

        def parse_geojson_feature(feature)
          score = feature['properties']['geocoding']['score']
          type = feature['properties']['geocoding']['type']
          label = feature['properties']['geocoding']['label']
          coordinates = feature['geometry']['coordinates'] if feature['geometry'] && feature['geometry']['coordinates']
          {lat: coordinates && coordinates[1], lng: coordinates && coordinates[0], quality: @@result_types[type], accuracy: score, free: label}
        end
      end

      resource :geocoder do
        desc 'Geocode.',
          detail: 'Return a list of address which match with input query.',
          nickname: 'geocode'
        params do
          requires :q, type: String, desc: 'Free query string.'
          optional :lat, type: Float, desc: 'Prioritize results around this latitude.'
          optional :lng, type: Float, desc: 'Prioritize results around this longitude.'
          optional :limit, type: Integer, desc: 'Max results numbers. (default and upper max 10)'
        end
        get 'search' do
          json = geocode(params[:q], 'France', params[:limit] || 10, params[:lat], params[:lng]).collect{ |result|
            {
              address: {
                city: result[:free]
              },
              boundingbox: [
                result[:lat],
                result[:lat],
                result[:lng],
                result[:lng]
              ],
              display_name: result[:free],
              importance: result[:accuracy],
              lat: result[:lat],
              lon: result[:lng],
            }
          }

          if params[:json_callback]
            content_type 'text/plain'
            "#{params[:json_callback]}(#{json.to_json})"
          else
            json
          end
        end
      end
    end
  end
end
