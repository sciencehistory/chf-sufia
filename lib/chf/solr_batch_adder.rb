module CHF

  # Just some logic for queuing up solr adds into batches. Not thread safe.
  class SolrBatchAdder
    attr_reader :solr_service_connection, :batch, :batch_size, :soft_commit, :commit
    def initialize(solr_service_connection: ActiveFedora::SolrService.instance.conn,
                   batch_size: 50,
                   soft_commit: false,
                   commit: false)
      @solr_service_connection = solr_service_connection
      @batch = []
      @batch_size = 50
      @sort_commit = soft_commit
      @commit = commit
    end

    # add to batch queue, submit queue if it's met batch size
    def add(hash)
      batch << hash

      if batch.count % batch_size == 0
        solr_service_connection.add(batch, softCommit: soft_commit, commit: commit)
        batch.clear
      end
    end

    # take care of any lingering uncommitted
    def finish
      if batch.present?
        solr_service_connection.add(batch, softCommit: true, commit: false)
        batch.clear
      end
    end

    # issue a hard commit to solr
    def commit
      solr_service_connection.commit
    end

  end
end
