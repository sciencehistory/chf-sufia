# DZI Tiles for Viewer, stored on S3

The [Deep Zoom](https://en.wikipedia.org/wiki/Deep_Zoom) format. for tiled-images supporting
full-res zoom, is not very well documented, but has become something of a standard, and
the original format understood by [OpenSeadragon](http://openseadragon.github.io/examples/tilesource-dzi/),
the javascript image viewer we use.

The format is basically a `($some_name).dzi` xml file, with a `($some_name)_files`
directory next to it containing subdirs with individual tiles at varying zoom levels.
The `.dzi` file can be passed directly to OpenSeadragon, it will find the tiles
at their conventional location.

We create .dzi and tiles on image upload, and upload them to S3.
* [CreateDziJob](../app/jobs/create_dzi_job.rb)
* [CreateDziService](../app/services/chf/create_dzi_service.rb) (uses the command-line program `vips`
  to create the dzi files. http://libvips.blogspot.com/2013/03/making-deepzoom-zoomify-and-google-maps.html.
  So vips must be installed on machine doing this. vips is really performance optimized
  for this operation, does a great job.)
* [AddFileToFileSetOverride](../app/overrides/hydra/works/add_file_to_file_set_override.rb)

The .dzi file is named with both file_id and fedora-calculated checksum, so
URLs will be indefinitely cacheable -- a given .dzi URL always refers
to the exact same tiles.

## CHF::Env variables

Certain mandatory and optional CHF::Env variables effect behavior. Check [actual
code for defaults](../app/models/chf/env.rb) in case this doc has not been kept up to date.

* `aws_access_key_id` -- required
* `aws_secret_access_key` -- required
* `dzi_s3_bucket` -- recommended, but may default to something reasonable in non-production
* `dzi_s3_bucket_region` -- defaults to `"us-east-1"`

* `dzi_job_tmp_dir` -- defaults to Rails.root ./tmp/dzi-creation-tmp-working. Where the
temporary original source and derivative files are kept by CreateDziService. The service
should clean up after itself, even on failures, so only needs enough disk space for concurrent
create operations.

* `dzi_auto_create` -- should DZI be created and uploaded to s3 on file upload? Currently defaults to true in production else false.

* `image_server_on_viewer` -- set to `dzi_s3` to use s3-stored DZI files

## Rake tasks

While DZI files should be created automatically on file upload, in case
something has gotten corrupted or out of sync or you want to re-generate
for whatever reason, there are rake tasks. Rake tasks should be run
on an instance set up with proper Env variables and repo connection.

* 'rake chf:dzi:configure_bucket' set CORS and any other bucket-level
  config. idempotent. (see http://docs.aws.amazon.com/AmazonS3/latest/user-guide/add-cors-configuration.html)

* `rake chf:dzi:push_all` -- create DZI and tiles or every file in the repo,
upload them to S3. Takes approximately 50 minutes per 1000 files.

* `rake chf:dzi:push_all[lazy]` only create DZI and tiles for a file in the
repo that does not currently have a .dzi on s3. Will not do anything
if there's already a .dzi. If there are no
files that need creating, only takes a couple minutes per 1000 files
in repo.

* `rake chf:dzi:clean_orphaned`. We don't actually automatically
delete .dzi and tiles when a file is deleted in repo, because
this is a rare occurence, and it was difficult to figure out
how to hook into stack to do this. But you can run this task to clean
up any orphaned .dzi or orphaned tiles without dzi from S3. Takes approx 60 seconds
per 1000 .dzi in S3, plus additional time if orphaned files are detected.

## In Dev

In default dev environment you do not get
DZI creation or deep zooming in viewer. You get a viewer with
limited viewing based on a large jpg derivative.

For more info on how to turn on production-style DZI zooming in
dev, see [Derivatives in Dev](./derivative_in_dev.md).

## Auth -- Not Yet

We currently have not implemented any auth for the .dzi and tiles in
S3. That means if someone discovers or calculates the proper URL, they
can look at tile images on S3 even for works/files not marked public
in our app.

Since nothing we have is actually particualrly senstive -- files
not marked public are typically just in workflow on the way to being
public--we decided not to prioritize this.

If we did want to do auth, we can think of a couple approaches, both
with some challenges.

* Set entire S3 bucket to private, proxy all access through something that
checks end-user session for auth, and supplies key to read to S3. **Cons:**
  * If this something is the app, may take up web worker connections.
  * May add latency to image access.

* Set S3 bucket to require signed URLs, generate signed and timestamped-expiring
  src URLs delivered to users only after chekcing auth in app. **Cons:**
  * URLs are not so HTTP-cacheable, since they are expiring and unique
    to every access.


