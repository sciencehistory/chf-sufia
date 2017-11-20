# Unclear how to customize the Sufia::CatalogSearchBuilder, which
# we need to do for blacklight_range_limit.
# https://github.com/projecthydra-labs/hyrax/issues/707

# to_prepare used in case there's dev-mode class reloading of the
# thing we're patching. But we try to check to not do it multiple
# times in case there isn't.
Rails.application.config.to_prepare do
  # would like to look up the class dynamically in case it changes,
  # Sufia does this weird making this the only way, Hyrax is somewhat
  # less weird.
  klass = CatalogController.new.search_builder_class
  unless klass.ancestors.include? BlacklightRangeLimit::RangeLimitBuilder
    klass.send(:include, BlacklightRangeLimit::RangeLimitBuilder)
  end

  unless klass.ancestors.include? SearchBuilder::RestrictAdminSearchFields
    klass.send(:include, SearchBuilder::RestrictAdminSearchFields)
  end

  unless klass.ancestors.include? SearchBuilder::SyntheticCategoryLimit
    klass.send(:include, SearchBuilder::SyntheticCategoryLimit)
  end

  unless klass.ancestors.include? SearchBuilder::PublicDomainFilter
    klass.send(:include, SearchBuilder::PublicDomainFilter)
  end

  unless klass.ancestors.include? SearchBuilder::PublicDomainFilter
    klass.send(:include, SearchBuilder::PublicDomainFilter)
  end

  unless klass.ancestors.include? SearchBuilder::CustomSortLogic
    klass.send(:include, SearchBuilder::CustomSortLogic)
  end

end
