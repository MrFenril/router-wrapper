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

require './wrappers/wrapper'

require 'uri'
require 'rest-client'
#RestClient.log = $stdout

module Wrappers
  class MapBox < Wrapper

    def initialize(cache, hash = {})
      super(cache, hash)
      @access_token = hash[:access_token]
      @url_matrix = hash[:url_matrix]
      # @url_isoline = {
      #   time: hash[:url_isochrone],
      #   distance: hash[:url_isodistance]
      # }
    end

    def route(locs, dimension, departure, arrival, language, with_geometry, options = {})
      throw NotImplementedError
    end

    def matrix(srcs, dsts, dimension, departure, arrival, language, options = {})
      destinations_index_start = srcs.length
      destinations_index_end = destinations_index_start + (dsts.length - 1)
      params = {
        coordinates: "#{format_coordinates_string(srcs)};#{format_coordinates_string(dsts)}",
        sources: "0;#{destinations_index_start - 1}",
        destinations: "#{destinations_index_start};#{destinations_index_end}",
        annotations: matrix_dimension(dimension)
      }

      response = RestClient.post(@url_matrix + "?access_token=#{@access_token}", params, { content_type: 'application/x-www-form-urlencoded'})
      results = JSON.parse(response)
      {
        router: {
          licence: 'MapBox',
          attribution: 'MapBox',
        },
        matrix_time: results['durations'],
        matrix_distance: results['distances']
      }
    end

    def isoline(loc, dimension, size, departure, _language, options = {})
      throw NotImplementedError
    end

    private

    def matrix_dimension(dimension)
      case dimension
      when :time
        'duration'
      when :distance
        'distance'
      when :time_distance
        'duration,distance'
      end
    end

    def format_coordinates_string(coordinates)
      idx = 0
      coordinates.reduce('') { |str, current|
        s = current.join(',')
        str += idx >= 1 && idx < coordinates.length ? (';' + s) : s
        idx += 1
        str
      }
    end
  end
end
