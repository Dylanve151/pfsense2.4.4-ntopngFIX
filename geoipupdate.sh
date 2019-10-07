#!/bin/sh

# You can set the following environment variables:
#
# GEOIP_DB_SERVER: The default download server is geolite.maxmind.com
# GEOIP_FETCH_CITY: If set (to anything), download the GeoLite City DB
# GEOIP_FETCH_ASN: If set, download the GeoIP ASN DB

#Fixed by Dylanve151 / Dylan-e

GEOIP_DB_SERVER=${GEOIP_DB_SERVER:=geolite.maxmind.com}
GEOIP_FETCH_CITY=${GEOIP_FETCH_CITY:=}
GEOIP_FETCH_ASN=${GEOIP_FETCH_ASN:=}

set -eu

# arguments:
# $1 URL
# $2 output file name
_fetch() {
    url="$1"
    out="$2"
	
    echo Fetching $2 from $1
    TEMPDIR="$(mktemp -d '/usr/local/share/GeoIP/GeoIPupdate.XXXXXX')"
    trap 'rc=$? ; set +e ; rm -rf "'"$TEMPDIR"'" ; exit $rc' 0
    if fetch -o "$TEMPDIR/$out.tar.gz" "$url"; then
        tar -x -C "$TEMPDIR" --strip-components 1 -f "$TEMPDIR/$out.tar.gz" "*/$out"
        chmod 444 "$TEMPDIR/$out"
        if ! mv -f "$TEMPDIR/$out" "/usr/local/share/ntopng/httpdocs/geoip/$2"; then
            echo "Unable to replace /usr/local/share/ntopng/httpdocs/geoip/$2"
            return 2
        fi
    else
        echo "$2 download failed"
        return 1
    fi
    rmdir "$TEMPDIR"
    trap - 0
    return 0
}

_fetch "https://${GEOIP_DB_SERVER}/download/geoip/database/GeoLite2-Country.tar.gz" GeoLite2-Country.mmdb
#_fetch "http://${GEOIP_DB_SERVER}/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz" GeoIP.dat
#_fetch "http://${GEOIP_DB_SERVER}/download/geoip/database/GeoIPv6.dat.gz" GeoIPv6.dat

if [ -n "$GEOIP_FETCH_CITY" ]; then
	_fetch "https://${GEOIP_DB_SERVER}/download/geoip/database/GeoLite2-City.tar.gz" GeoLite2-City.mmdb
	#_fetch "http://${GEOIP_DB_SERVER}/download/geoip/database/GeoLiteCity.dat.gz" GeoLiteCity.dat
	#_fetch "http://${GEOIP_DB_SERVER}/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz" GeoLiteCityv6.dat
fi
if [ -n "$GEOIP_FETCH_ASN" ]; then
	fetch "https://${GEOIP_DB_SERVER}/download/geoip/database/GeoLite2-ASN.tar.gz" GeoLite2-ASN.mmdb
	#_fetch "http://${GEOIP_DB_SERVER}/download/geoip/database/asnum/GeoIPASNum.dat.gz" GeoIPASNum.dat
	#_fetch "http://${GEOIP_DB_SERVER}/download/geoip/database/asnum/GeoIPASNumv6.dat.gz" GeoIPASNumv6.dat
fi
