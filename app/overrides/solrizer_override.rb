# Solrizer.solr_name is called a LOT of times on our 'show' page, and
# seems to be very slow for some reason. Profiling revealed it as a bottleneck.
# We override to cache it's response, to make it quick on non-first call with
# certain args.

module SolrizerOverride
  @@solr_name_cache = {}
  def solr_name(*args)
    @@solr_name_cache[args] ||= super
  end
end

# This weird construction was what I figured out that made prepend
# on the class object, so we could call super, work out.
Solrizer.class_eval do
  class << self
    prepend SolrizerOverride
  end
end

