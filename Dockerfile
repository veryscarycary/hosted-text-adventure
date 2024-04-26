# Use the official Ruby 2.7.0 image as the base image
FROM ruby:2.7.0

# Set the working directory inside the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock from your project directory into the container
COPY Gemfile Gemfile.lock ./

# Install dependencies
RUN bundle install

# Copy the rest of your application code into the container
COPY . .

# Set the command to run your application
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "3000", "app.rb"]
