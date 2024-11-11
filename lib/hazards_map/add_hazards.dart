import 'package:maplibre_gl/maplibre_gl.dart';

const evacuationFireUrl = "https://services3.arcgis.com/uknczv4rpevve42E/arcgis/rest/services/CA_EVACUATIONS_PROD/FeatureServer/0/query/?spatialRel=esriSpatialRelIntersects&f=geojson&where=SHAPE__Area>0&outFields=*";

void addHazards(MapLibreMapController map) async {
  
}