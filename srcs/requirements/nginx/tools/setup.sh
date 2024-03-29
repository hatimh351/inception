#!/bin/sh

apk update
apk add nginx
apk add openssl

TLS_CONF_DIR=/TLS

CRT_DIR=$TLS_CONF_DIR/CRT
PRIV_KEY_DIR=$TLS_CONF_DIR/PRIV_KEY
CSR_DIR=$TLS_CONF_DIR/CRS

PRIVKEY=private.key
CRS=crs.csr
CRT=crt.crt


mkdir -p $CRT_DIR $PRIV_KEY_DIR $CSR_DIR
mkdir -p /app
chown -R nginx:www-data /app
chmod -R 755 /app



echo "Creating private key "
openssl genrsa -out  "${PRIV_KEY_DIR}/${PRIVKEY}" 2048

echo "Creating the certificate signing request "

openssl req -key "${PRIV_KEY_DIR}/${PRIVKEY}" -new -out "${CSR_DIR}/${CRS}" -subj "/C=MR/ST=./L=./O=./OU=./CN=."


echo "Signing the certificate"

openssl x509 -signkey "${PRIV_KEY_DIR}/${PRIVKEY}" -in "${CSR_DIR}/${CRS}" -req -days 365 -out "${CRT_DIR}/${CRT}"



echo '''

server
{
	listen 443 ssl;
	ssl_certificate /TLS/CRT/crt.crt;
    ssl_certificate_key /TLS/PRIV_KEY/private.key;
	ssl_protocols TLSv1.3;

	root /app;

	index index.php;

	
	location ~ \.php$ {
        	include fastcgi.conf;
        	fastcgi_pass wordpress:9000;
    	}

}
''' > /etc/nginx/http.d/default.conf
