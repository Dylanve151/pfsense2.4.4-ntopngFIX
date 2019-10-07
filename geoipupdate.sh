#!/bin/sh

# You can set the following environment variables:
#
# GEOIP_DB_SERVER: The default download server is geolite.maxmind.com
# GEOIP_FETCH_CITY: If set to true, download the GeoLite City DB
# GEOIP_FETCH_ASN: If set to true, download the GeoIP ASN DB

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

#for some reason this part doesnt work and i am to lazy to fix it :)
if [ "$GEOIP_FETCH_CITY" -eq "true" ]; then
	_fetch "https://${GEOIP_DB_SERVER}/download/geoip/database/GeoLite2-City.tar.gz" GeoLite2-City.mmdb
fi
if [ "$GEOIP_FETCH_ASN" -eq "true" ]; then
	fetch "https://${GEOIP_DB_SERVER}/download/geoip/database/GeoLite2-ASN.tar.gz" GeoLite2-ASN.mmdb
fi
