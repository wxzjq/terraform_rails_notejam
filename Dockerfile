FROM ruby:2.5.3

#Environment variables
ENV APP_HOME /notejam

# Installation of dependencies
RUN apt-get update -qq \
    && apt-get install -y \
    # Needed for certain gems
    build-essential \
    # Needed for postgres gem
    libpq-dev \
    # Needed for json extension
    libgmp3-dev \
    # Needed for asset compilation
    nodejs \
    # The following are used to trim down the size of the image by removing unneeded data
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf \
    /var/lib/apt \
    /var/lib/dpkg \
    /var/lib/cache \
    /var/lib/log

# Create application directory
# and set it as current
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# Install gems
COPY Gemfile* $APP_HOME/
RUN bundle install

# Copy over our application code
COPY . . 

# Fake database URL tricks rake into running assets:precompile step that does not require database access 
RUN DATABASE_URL=postgresql://something/something bundle exec rake assets:precompile

# Run our app script
CMD bash ./start.sh 3000 