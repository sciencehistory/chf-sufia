# Customized Derivatives Architecture

By "derivatives", we mean files created from the original archival assets -- our ad cases currently, various-sized JPGs, for in-browser thumbs, and downloads, created from our TIFFs.

See also, related, [our DZI tile for deep zoom](./dzi_tiles_on_s3.md) stuff.

For turning on production-style derivatives in dev or test, see [Derivatives in Dev](./derivative_in_dev.md).

## Background/Motivation

Stock Sufia (and Hyrax at the time of this writing) uses [hydra-derivatives](https://github.com/samvera/hydra-derivatives) to control the creation of these derivatives. In stock sufia, URLs to thumbnails in browser are kind of hard-coded assuming a certain derivative stored a certain way.

We found hydra-derivatives not meeting our needs, and would require so much monkey-patching and customization to make it do so, for relatively straightforward functionality, that it made sense to just write our own.

1. Make sure derivatives creation job could run on a different server
than Rails app, and clean up it's temporary files.

2. Store derivatives on AWS S3 (to avoid need for shared fs when running on differnet server, and cause S3 just makes sense here)

3. Use vips instead of ImageMagick for performance. And other performance-related tweaks.

4. Customize the image processing params, to follow best practices for minimizing size for web thumbs, and different best practices for downloadable JPGs.

5. To integrate a bit better into a custom front-end system to display thumbs and downloads, that we would need to add custom anyway to support our front-end needs, including different sized thumbs in different parts of the page, and proper use of srcset.

## Our Implementation

### Creation of derivatives

The main class that CREATES the derivatives is [CreateDerivativesOnS3Service](../app/services/chf/create_derivatives_on_s3_service.rb). It's _relatively_ straightforward. Note that the different derivatives each have a definition with a key, that can be used to refer to them, for maintenance tasks or importantly for _getting a url_. Note that CreateDerivativesOnS3 has some url
generation in it too.

We [monkey-patch the standard CreateDerivativesJob](../app/jobs/create_derivatives_job_override.rb) to call our new service.

Note that `work.create_derivatives` no longer does so, it'll create the old-style derivatives if it does anything. No other parts of sufia use this
method except the parts we changed. It doesn't make sense to have this on the model, we like it better in our service.

### Job on different server

We want the CreateDerivativesJob to run on our jobs server, not app. Our override changes it's queue name, and our [resque-pool config](../config/resque-pool.yml) uses a CHF::Env config such that workers on jobs server pull that queue, and workers on app server (with legacy jobs) do not.

### Display or use of derivatives

Standard sufia views, I believe, assume only one size thumbnail, stored via legacy method, and have no provision for downloads.  So we had to customize this one way or another. Back when we were experimenting with a bunch of different IIIF servers, we built a bit of abstraction to let us configure the source of some images with configuration. We expanded that for our new derivatives system, with more universal use (including in sufia admin screens),
supporting downloads, etc.

The [ImageServiceHelper](../app/helpers/image_service_helper.rb) is the entry point to that abstraction. It's a rails-style helper (which may or may not have been the best call, but it's what we've got for now). Code that wants a derivative URL should get it through one of these methods. Such as:

  member_src_attributes(entity, size_key: :standard)
    # => returns a hash with 'src' and possibly 'srcset' too.

That helper also has methods used for generating the JSON configuration that
feeds the custom viewer, so it knows what downloads are available and where
to get thumbs.

You can see the `_image_url_service` method and `self.image_url_service_class` class method in ImageServiceHelper, that depending on feature flags work to choose a different "adapter" object to actually provide functionality.

Note that for download links, our CHF::DziS3UrlService uses S3 api to
set, just-in-time, a content-disposition header with filename to 'save as'.

### NOTE: no Auth

Much like for [dzi](./dzi_tiles_on_s3.md), and with the same motivations, we aren't currently doing any auth, derivatives can be accessed by anyone if they know the URL.

### Feature flags

As mentioned, there are 'feature flags' that can switch between different
types of derivative provision or creation. These are handled by [CHF::Env](../app/models/chf/env.rb), either via a config/local_env.yml (ansible provided
in production), or through OS ENV (can be handy in dev).

These three can each be `dzi_s3` (current), `iiif` (not used), or nil (legacy sufia) -- and control what images are used for thumbnails, for OpenSeadragon tiles, and for downloads, respectively. `image_server_for_thumbnails`, `image_server_on_viewer`, `image_server_downloads`

`create_derivatives_mode` controls what derivatives are automatically created
on ingest, and can be `dzi_s3` or `legacy`.

If using the new dzi_s3 system discussed here, you need some AWS-related keys as well. `aws_access_key_id`, `aws_secret_access_key`, `derivative_s3_bucket`.


### Original PR

https://github.com/chemheritage/chf-sufia/pull/889

## Maintenance

### Cleanup

Currently we haven't monkey-patched in ever _deleting_ derivatives when/if
the corresonding original is deleted. You can run the rake task:

    rake chf:derivatives:s3:clean_orphaned

### Creation via rake task

To create all derivatives and store them on S3, you can run:

    rake chf:derivatives:s3:create

This will take quite a while to run, if creating all of them. (~30 hours for ~15000 images). You can also tell it to do a lazy creation, only creating
derivatives that don't already exist. With 15000 iamges, it takes it about 70 minutes to confirm all exist.

    rake chf:derivatives:s3:create[lazy]

You can also tell it to create derivatives only for certain works (all images in that work, may not fall through to child works though); or only for certain styles or types or derivatives. Together or in combination.  Can also be combined with 'lazy'.

    WORK_IDS=adf823423,adf8734adf rake chf:derivatives:s3:create
    ONLY_STYLES=thumb rake chf:derivatives:s3:create
    ONLY_TYPES=dl_large,dl_medium rake chf:derivatives:s3:create
    WORK_IDS=adf823423 ONLY_TYPES=dl_large,dl_medium rake chf:derivatives:s3:create[lazy]


The 'styles' and 'types' are as in the derivative type definitions in [CreateDerivativesOnS3Service](../app/services/chf/create_derivatives_on_s3_service.rb).

### Old-style derivatives

If you need to create derivatives using the old legacy sufia way (in terms of both processing and storage), there is a rake task available, but it doens't
currently have all those fancy options, it pretty much just creates all of em.

    rake chf:derivatives:legacy:create

## Future

This code seems to work, but it definitely got a bit messy. It also has some things hard-coded for us, so is not shareable as is upstream -- it would need more work, it's not ready.

I have been discussing to see if there's interest in the community in taking what we've learned here and preparing a more general purpose and solidly done alternative/replacement to hydra-derivatives.
