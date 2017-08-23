# Were previously having some weird NameErrors in resque jobs.
# https://github.com/aws/aws-sdk-ruby/issues/1233
if Rails.env.production? && defined?(Aws)
  Aws.eager_autoload!(services: ['S3'])
end
