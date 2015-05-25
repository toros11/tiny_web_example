#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -u
set -x

YUM_HOST="${YUM_HOST:-"10.0.22.100"}"
DB_HOST="${DB_HOST:-"10.0.22.101"}"

# install tiny-web-example.repo
cat <<-EOS > /etc/yum.repos.d/tiny-web-example.repo
	[tin-web-example]
	name=tiny-web-example
	baseurl=http://${YUM_HOST}/pub/
	enabled=1
	gpgcheck=0
	EOS

# show available repo list
yum repolist

# install tiny-web-example.rpm
yum install -y tiny-web-example

## /etc/default/tiny-web-example-webapi
cat <<-'EOS' > /etc/default/tiny-web-example-webapi
	# tiny-web-example
	EXAMPLE_ROOT=/opt/axsh/tiny-web-example
	PATH=/root/.rbenv/shims:$PATH

	# Commnet out to run the vdc init script.
	#RUN=yes

	## rack params
	RACK_ENV=development
	BIND_ADDR=0.0.0.0
	PORT=8080
	UNICORN_CONF=/etc/tiny-web-example/unicorn-common.conf
	EOS

## /etc/default/tiny-web-example-webapp
cat <<-'EOS' > /etc/default/tiny-web-example-webapp
	# tiny-web-example
	EXAMPLE_ROOT=/opt/axsh/tiny-web-example
	PATH=/root/.rbenv/shims:$PATH

	# Commnet out to run the vdc init script.
	#RUN=yes

	## rack params
	RACK_ENV=development
	BIND_ADDR=0.0.0.0
	PORT=80
	UNICORN_CONF=/etc/tiny-web-example/unicorn-common.conf
	EOS

# configure db host
sed -i \
 "s,^database_uri .*,database_uri 'mysql2://${DB_HOST}/tiny_web_example?user=root'," \
 /etc/tiny-web-example/webapi.conf /etc/tiny-web-example/webapp.yml

# setup db
cd /opt/axsh/tiny-web-example/webapi/
bundle exec rake db:up

# start system jobs
initctl start tiny-web-example-webapi RUN=yes
initctl start tiny-web-example-webapp RUN=yes
