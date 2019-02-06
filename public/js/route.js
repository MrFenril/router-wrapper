(function(options) {

  function init(data) {
    var geocoderLayer
    var routing, map, geocoder;
    var waypoints = [];

    function getMode() {
      return $('#router-mode').val();
    }

    function getDimension() {
      return $('#router-dimension').val();
    }

    function getTrack() {
      return $('#track').is(':checked');
    }

    function getMotorway() {
      return $('#motorway').is(':checked');
    }

    function getToll() {
      return $('#toll').is(':checked');
    }

    function resetMap() {
      map.removeControl(routing);
      map.removeControl(geocoder);
      map.removeLayer(geocoderLayer);
    }

    function initMap() {
      geocoderLayer = L.featureGroup();

      map.addLayer(geocoderLayer);

      routing = L.Routing.control({
        router: L.Routing.mt($.extend(options, {
          mode: getMode(),
          dimension: getDimension(),
          track: getTrack(),
          motorway: getMotorway(),
          toll: getToll()
        })),
        waypoints: waypoints,
        routeWhileDragging: true
      }).addTo(map);

      geocoder = L.Control.geocoder({
        geocoder: L.Control.Geocoder.nominatim({
          serviceUrl: "/0.1/geocoder/",
          geocodingQueryParams: { api_key: options.apiKey }
        }),
        position: 'topleft',
        placeholder: 'Recherche d\'adresse...',
        errorMessage: 'Pas de résultat',
        defaultMarkGeocode: false
      })
      .on('markgeocode', function(e) {
        this._map.fitBounds(e.geocode.bbox, {
          maxZoom: 15,
          padding: [20, 20]
        });
        var focusGeocode = L.marker(e.geocode.center, {
          icon: new L.divIcon({
            html: '',
            iconSize: new L.Point(14, 14),
            className: 'focus-geocoder'
          })
        }).addTo(geocoderLayer);
        setTimeout(function() {
          geocoderLayer.removeLayer(focusGeocode);
        }, 2000);
      })
      .addTo(map);

      $('.leaflet-control-geocoder-icon').prop('title', 'Rechercher une addresse');
    }

    function initDimensions(mode) {
      function capitalizeFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
      }
      var select = $('#router-dimension');
      select.find('option').remove();
      $.each(data.route, function(i, item) {
        if (item.mode == mode) {
          $.each(item.dimensions, function(k, v) {
            select.append(
              $('<option>').val(v).html(capitalizeFirstLetter(v))
            )
          });
        }
      });
    }

    function createButton(label, container) {
      var btn = L.DomUtil.create('button', '', container);
      btn.setAttribute('type', 'button');
      btn.innerHTML = label;
      return btn;
    }

    $.each(data.route, function(i, item) {
      $('#router-mode').append(
        $('<option>').val(item.mode).html(item.name)
      )
    });

    $('#router-mode').change(function(e) {
      initDimensions(getMode());
    });

    var mode = getMode();
    map = L.map('map').setView(L.latLng(44.823360, -0.651695), 10);
    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
      attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors',
    }).addTo(map);
    initDimensions(mode);
    initMap(mode);
    $('select').select2({ minimumResultsForSearch: -1 });
    $('select, input').change(function(e) {
      resetMap();
      initMap();
    });

    routing.getPlan().on('waypointschanged', function(e) {
      waypoints = e.waypoints;
    });

    routing.getPlan().on('waypointdragend', function(e) {
      waypoints = routing.getPlan()._waypoints;
    });

    map.on('click', function(e) {
      var container = L.DomUtil.create('div');
          startBtn = createButton('Start from this location', container),
          destBtn = createButton('Go to this location', container);

      L.popup().setContent(container).setLatLng(e.latlng).openOn(map);

      L.DomEvent.on(startBtn, 'click', function() {
        routing.spliceWaypoints(0, 1, e.latlng);
        map.closePopup();
      });

      L.DomEvent.on(destBtn, 'click', function() {
        routing.spliceWaypoints(routing.getWaypoints().length - 1, 1, e.latlng);
        map.closePopup();
      });
    });
  }

  $.ajax({
    url: options.serviceUrl + '/capability',
    type: 'GET',
    dataType: 'json',
    data: { api_key: options.apiKey },
    success: function(data, textStatus, jqXHR) {
      init(data);
    }
  });

})({
  serviceUrl: '0.1',
  apiKey: 'demo'
});
