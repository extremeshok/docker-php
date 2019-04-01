<html>
<body>
<?php
<h2>GEOIPv1</h2>
$geoip_country_code = getenv(GEOIP_COUNTRY_CODE);
/*
$geoip_country_code = $_SERVER['GEOIP_COUNTRY_CODE']; // works as well
*/
$geoip_country_code3 = getenv(GEOIP_COUNTRY_CODE3);
$geoip_country_name = getenv(GEOIP_COUNTRY_NAME);
$geoip_city_country_code = getenv(GEOIP_CITY_COUNTRY_CODE);
$geoip_city_country_code3 = getenv(GEOIP_CITY_COUNTRY_CODE3);
$geoip_city_country_name = getenv(GEOIP_CITY_COUNTRY_NAME);
$geoip_region = getenv(GEOIP_REGION);
$geoip_city = getenv(GEOIP_CITY);
$geoip_postal_code = getenv(GEOIP_POSTAL_CODE);
$geoip_city_continent_code = getenv(GEOIP_CITY_CONTINENT_CODE);
$geoip_latitude = getenv(GEOIP_LATITUDE);
$geoip_longitude = getenv(GEOIP_LONGITUDE);
echo 'country_code: '.$geoip_country_code.'<br>';
echo 'country_code3: '.$geoip_country_code3.'<br>';
echo 'country_name: '.$geoip_country_name.'<br>';
echo 'city_country_code: '.$geoip_city_country_code.'<br>';
echo 'city_country_code3: '.$geoip_city_country_code3.'<br>';
echo 'city_country_name: '.$geoip_city_country_name.'<br>';
echo 'region: '.$geoip_region.'<br>';
echo 'city: '.$geoip_city.'<br>';
echo 'postal_code: '.$geoip_postal_code.'<br>';
echo 'city_continent_code: '.$geoip_city_continent_code.'<br>';
echo 'latitude: '.$geoip_latitude.'<br>';
echo 'longitude: '.$geoip_longitude.'<br>';
?>
<h2>GEOIPv2</h2>
<?php
$geoip_country_code = getenv(GEOIP2_COUNTRY_ISO_CODE);
/*
$geoip_country_code = $_SERVER['GEOIP2_COUNTRY_ISO_CODE']; // works as well
*/
$geoip_country_name = getenv(GEOIP2_COUNTRY);
$geoip_region = getenv(GEOIP2_REGION_NAME);
$geoip_city = getenv(GEOIP2_CITY);
$geoip_postal_code = getenv(GEOIP2_POSTAL_CODE);
$geoip_city_continent_code = getenv(GEOIP2_CONTINENT_CODE);
$geoip_latitude = getenv(GEOIP2_LATITUDE);
$geoip_longitude = getenv(GEOIP2_LONGITUDE);

$geoip_country_in_eu = getenv(GEOIP2_COUNTRY_IN_EU);
$geoip_location_radius = getenv(GEOIP2_LOCATION_ACCURACY_RADIUS);
$geoip_registered_country_code = getenv(GEOIP2_REGISTERED_COUNTRY_ISO);

echo 'country_code: '.$geoip_country_code.'<br>';
echo 'country_name: '.$geoip_country_name.'<br>';
echo 'region: '.$geoip_region.'<br>';
echo 'city: '.$geoip_city.'<br>';
echo 'postal_code: '.$geoip_postal_code.'<br>';
echo 'city_continent_code: '.$geoip_city_continent_code.'<br>';
echo 'latitude: '.$geoip_latitude.'<br>';
echo 'longitude: '.$geoip_longitude.'<br>';
echo 'country in eu: '.$geoip_country_in_eu.'<br>';
echo 'location accuracy radius: '.$geoip_location_radius.'<br>';
echo 'registered country code for IP: '.$geoip_registered_country_code.'<br>';
?>
</body>
</html>
