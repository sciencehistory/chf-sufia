# Derivatives and DZI in Dev or Test Environment

As discussed, we have custom systems that store [derivatives](our_custom_derivatives.md) and [dzi](dzi_tiles_on_s3.md) on AWS S3.

In development and testing, it may be a pain to get that set up, and not always needed. So by default, in development environment, the app _does not use them_, using old-style 'legacy' derivatives (thumbs and no downloads), and
a not-really-deep-zoom thumb in viewer.

However, it is easy to turn them on in dev. You'll need an S3 bucket to use for dzi, and a different one to use for derivatives. (Either your own or one you share with other developers). And AWS credentials giving you access to those.

You can turn different features on separately to use 'new' style. Either in a ./config/local_env.yml, or in your system ENV (perhaps set in `.bash_profile`)

For instance, in ENV:

```
export AWS_ACCESS_KEY_ID=$your_key_id
export AWS_SECRET_ACCESS_KEY=$your_key
export DZI_S3_BUCKET=$your_dzi_bucket
export DERIVATIVES_S3_BUCKET=$your_derivatives_bucket
export IMAGE_SERVER_ON_VIEWER=dzi_s3
export IMAGE_SERVER_FOR_THUMBNAILS=dzi_s3
export IMAGE_SERVER_DOWNLOADS=dzi_s3
export CREATE_DERIVATIVES_MODE=dzi_s3
```

Or, with the same keys, lowercased, in a local_env.yml.
