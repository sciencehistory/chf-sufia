This patch backports improvements in fixity checking services from
Hyrax to our app.

The Hyrax fixes are not expected to be until Hyrax 2.0.

We were on Sufia 7.3.0 at time this patch was made.

https://github.com/projecthydra-labs/hyrax/pull/984
https://github.com/projecthydra-labs/hyrax/pull/1015

Names were left under "Hyrax" namespace for easier copy and paste into
this patch, but some changes to internal implementation were made to
not rely on other "Hyrax" namespaced infrastructure outside of this patch,
but instead use our current "Sufia" infrastructure.

This also includes an ActiveFedora backport, to return expected_message_digest,
that is used by the Hyrax backport.

It is expected this entire patch can be removed when we are on a hyrax
implementing https://github.com/projecthydra-labs/hyrax/pull/984 / 1015

And AF 11.3 or otherwise inclusion of:
https://github.com/projecthydra/active_fedora/pull/1239
