module CHF

  # A custom fedora-to-solr indexer for us.
  #
  # Originally this was same as default but included enhancmeents that had been PR'd to
  # AF, but not yet released.
  #   https://github.com/projecthydra/active_fedora/pull/1219
  #   https://github.com/projecthydra/active_fedora/pull/1218
  #
  # However, we've since customized more, to improve things are meet our needs, including
  # some changes to API (pass options in initializer not reindex method), a delete_preivous option,
  # etc. so we have no plan to go back to mainline released indexer, this one is better (for us at least).
  # Sorry, them's the breaks.
  class Indexer

    attr_reader :batch_size, :softCommit, :use_progress_bar, :progress_bar, :final_commit, :delete_previous

    def initialize(batch_size: 50,
                  softCommit: true,
                  progress_bar: false,
                  final_commit: false,
                  delete_previous: false)
      @batch_size = batch_size
      @softCommit = softCommit
      @use_progress_bar = progress_bar
      @final_commit = final_commit
      @delete_previous = delete_previous
    end

    def reindex_everything
      s_time = Time.now.localtime
      log "fetching all URIs from fedora at #{s_time}, might take 20+ minutes?..."
      descendants = descendant_uris(ActiveFedora.fedora.base_uri)
      log "fetched all URIs from fedora at #{Time.now.localtime} in: #{(Time.mktime(0)+(Time.now.localtime - s_time)).strftime("%H:%M:%S")}"

      if delete_previous
        latest_previous_record = ActiveFedora::SolrService.query("*:*", rows: 1, sort: "timestamp desc").first
        latest_previous_timestamp = latest_previous_record && latest_previous_record["timestamp"].presence
      end


      batch = []

      @progress_bar = ProgressBar.create(total: descendants.count, format: "%t: |%B| %p%% %e") if use_progress_bar

      descendants.each do |uri|
        # skip root url
        next if uri == ActiveFedora.fedora.base_uri

        begin
          log("Re-index everything ... #{uri}", level: :debug)
          batch << ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).to_solr
          if (batch.count % batch_size).zero?
            ActiveFedora::SolrService.add(batch, softCommit: softCommit)
            batch.clear
          end
        rescue Ldp::Gone
          log("Re-index everything hit Ldp::Gone with uri #{uri}")
        end

        @progress_bar.increment if @progress_bar
      end

      if batch.present?
        ActiveFedora::SolrService.add(batch, softCommit: softCommit)
        batch.clear
      end

      @progress_bar.finish if @progress_bar

      if delete_previous && latest_previous_timestamp
        log("Deleting everything last updated before #{latest_previous_timestamp}...")
        ActiveFedora::SolrService.instance.conn.delete_by_query("timestamp:[* TO #{latest_previous_timestamp}]")
        log("   ...done deleting at #{Time.now.localtime}")
      end


      if final_commit
        log("Solr hard commit at #{Time.now.localtime}...")
        ActiveFedora::SolrService.commit
      end
      finish_t = Time.now.localtime
      log "index complete at #{finish_t}, total time #{(Time.mktime(0) + (finish_t - s_time)).strftime("%H:%M:%S")}"
    end

    def descendant_uris(uri)
      DescendantFetcher.new(uri).descendant_and_self_uris
    end

    def log(msg, level: :info)
      if level.to_s != "debug"
        if use_progress_bar && progress_bar
          progress_bar.log(msg)
        elsif use_progress_bar # interactive but no controller currently
          $stderr.puts msg
        end
      end

      # log to log regardless
      Rails.logger.send(level, "#{self.class.name}: #{msg}")
    end
  end
end
