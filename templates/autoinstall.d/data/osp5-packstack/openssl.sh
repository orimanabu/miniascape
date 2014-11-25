#!/bin/bash

ssldir=/etc/keystone/ssl
certdir=${ssldir}/certs
privdir=${ssldir}/private

echo "=> openssl.conf"
cat ${certdir}/openssl.conf

echo "=> index.txt"
cat ${certdir}/index.txt

for file in ${certdir}/{01,ca,signing_cert}.pem; do
	echo "==> ${file} (x509)"
	openssl x509 -text -noout -in ${file}
done

for file in ${certdir}/req.pem; do
	echo "==> ${file} (x509)"
	openssl req -text -noout -in ${file}
done

for file in ${privdir}/*.pem; do
	echo "==> ${file} (rsa)"
	openssl rsa -text -noout -in ${file}
done
