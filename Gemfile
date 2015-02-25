source "https://rubygems.org"

gem "openc-schema", github: "OpenAddressesUk/openc-schema"
gem "turbot-runner", github: "OpenAddressesUk/turbot-runner"
gem "turbot-api", github: "OpenAddressesUk/turbot-api"

gemspec

group :development, :test do
  gem "rake",  ">= 0.8.7"
  gem "rr",    "~> 1.0.2"
  gem "excon"
end

group :development do
  gem "aws-s3"
  gem "fpm"
  gem "pry"
end

group :test do
  gem "fakefs"
  gem "jruby-openssl", :platform => :jruby
  gem "json"
  gem "rspec", "~> 2.0"
  gem "sqlite3"
  gem "webmock"
end
