var contentString = new Array(window.data["objects"].length);
var positionArray = new Array(window.data["objects"].length);
var markerArray   = new Array(window.data["objects"].length);

for (var i = 0; i < window.data["objects"].length; i++) {
  // Pop-up info
  contentString[i] = '<div class="content">'
    + '<a href="/dashboard/nodes/2">test</a>'
    + '<div class="bodyContent">'
    + i.toString()
    + '</div>'
    + '</div>';

  positionArray[i] = new google.maps.LatLng( window.data["objects"][i]["latitude"], window.data["objects"][i]["longitude"] );
}

function initialize() {

  var lat1 = window.data["objects"][0]["latitude"];
  var lng1 = window.data["objects"][0]["longitude"];
  var latLng1 = new google.maps.LatLng( lat1, lng1 );

  // Map options
  var mapOptions = {
    center: latLng1,
    zoom: 22,
    mapTypeId: google.maps.MapTypeId.SATELLITE
  };

  // Initialize map
  var map = new google.maps.Map( document.getElementById('map-canvas'), mapOptions );

  setMarkers(map, window.data["objects"]);
  infowindow = new google.maps.InfoWindow({
    content: "loading..."
  });
}

function setMarkers(map, markers) {

  for (var i = 0; i < markers.length; i++) {
    var site = markers[i];
    var siteLatLng = new google.maps.LatLng(site["latitude"], site["longitude"]);
    var marker = new google.maps.Marker({
      position: siteLatLng,
      map: map,
      title: site["id"].toString(),
      icon: '/darkgreen.png',
      html: contentString[i]
    });

    var content = "Some content";

    google.maps.event.addListener(marker, "click", function() {
      infowindow.setContent(this.html);
      infowindow.open(map, this);
    });
  }

}

google.maps.event.addDomListener( window, 'load', initialize );
