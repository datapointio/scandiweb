#!/bin/bash

apt-get update
apt-get install -y varnish

sed -i -e 's/:6081/:80/g' /lib/systemd/system/varnish.service
systemctl daemon-reload

cat >/etc/varnish/default.vcl <<EOL
vcl 4.0;

backend default {
    .host = "$1";
    .port = "80";
}

sub vcl_recv {

}

sub vcl_backend_response {

}

sub vcl_deliver {

}
EOL

/etc/init.d/varnish restart

exit 0
