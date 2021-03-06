# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register 'application/x-endnote-refer', :endnote

Mime::Type.register "application/n-triples", :nt
Mime::Type.register "application/ld+json", :jsonld
Mime::Type.register "text/turtle", :ttl

Mime::Type.register "application/x-research-info-systems", :ris
Mime::Type.register "application/vnd.citationstyles.csl+json", :csl

Mime::Type.register "audio/mpeg",   :mp3
Mime::Type.register "audio/flac",   :flac
Mime::Type.register "audio/x-flac", :flac
