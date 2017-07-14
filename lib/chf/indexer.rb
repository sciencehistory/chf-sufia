module CHF

  # This code in ActiveFedora master but not yet released, we shouldn't need
  # a custom indexing routine once it is, can just use ActiveFedora::Base.reindex_everything
  #
  # https://github.com/projecthydra/active_fedora/pull/1219
  # https://github.com/projecthydra/active_fedora/pull/1218
  if Gem.loaded_specs["active-fedora"].version >= Gem::Version.new('11.2')
     msg = "\n\nPlease check and make sure this patch is still needed at #{__FILE__}:#{__LINE__}\n\n"
     $stderr.puts msg
     Rails.logger.warn msg
  end

  # A custom fedora-to-solr indexer that uses code submitted to ActiveFedora
  # but not yet released.
  class Indexer
    def reindex_everything(batch_size: 50, softCommit: true, progress_bar: false, final_commit: false)
      s_time = Time.now.localtime
      $stderr.puts "fetching all URIs from fedora at #{s_time}, might take 20+ minutes?..."
      descendants = descendant_uris(ActiveFedora.fedora.base_uri)
      $stderr.puts "fetched all URIs from fedora at #{Time.now.localtime} in: #{(Time.mktime(0)+(Time.now.localtime - s_time)).strftime("%H:%M:%S")}"


      batch = []

      progress_bar_controller = ProgressBar.create(total: descendants.count, format: "%t: |%B| %p%% %e") if progress_bar

      descendants.each do |uri|
        # skip root url
        next if uri == ActiveFedora.fedora.base_uri

        begin
          Rails.logger.debug "Re-index everything ... #{uri}"
          batch << ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).to_solr
          if (batch.count % batch_size).zero?
            ActiveFedora::SolrService.add(batch, softCommit: softCommit)
            batch.clear
          end
        rescue Ldp::Gone
          Rails.logger.warn "Re-index everything hit Ldp::Gone with uri #{uri}"
        end

        progress_bar_controller.increment if progress_bar_controller
      end

      if batch.present?
        ActiveFedora::SolrService.add(batch, softCommit: softCommit)
        batch.clear
      end

      progress_bar_controller.finish

      if final_commit
        $stderr.puts "Solr hard commit at #{Time.now.localtime}..."
        ActiveFedora::SolrService.commit
      end
      $stderr.puts "chf:index complete at #{Time.now.localtime}"
    end

    def descendant_uris(uri)
      DescendantFetcher.new(uri).descendant_and_self_uris
    end
  end
end
