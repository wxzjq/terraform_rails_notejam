#!/bin/sh
bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup

RAILS_SERVE_STATIC_FILES=true bundle exec rails s -p $1 -b '0.0.0.0'