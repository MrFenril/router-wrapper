# Copyright © Mapotempo, 2015-2016
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
require './test/test_helper'

require './wrappers/mapbox'

class Wrappers::MapBoxTest < Minitest::Test

  def test_router_matrix
    mapbox = RouterWrapper::MAPBOX
    srcs = [[-117.17282, 32.71204], [-117.17288, 32.71225], [-117.17293, 32.71244], [-117.17292, 32.71256]]
    dsts = [[-117.17298,32.712603], [-117.17314,32.71259], [-117.17334,32.71254]]
    # vector = [[44.82641, -0.55674], [44.85284, -0.5393]]
    result = mapbox.matrix(srcs, dsts, :time_distance, nil, nil, 'en')
    assert_equal "MapBox", result[:router][:licence]
    assert_equal 2, result[:matrix_time].length
    assert_equal 2, result[:matrix_distance].length
  end

end
