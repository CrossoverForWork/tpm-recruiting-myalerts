FROM ruby:2.3
MAINTAINER Adam Gray "adam@myalerts.com"

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
#RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository (v9.4)
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg 9.4" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && apt-get install -y postgresql-client

# Update & cleanup dependency installation
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

# Configure for parallel jobs & install
RUN bundle config --global jobs 4
RUN bundle install --without production
