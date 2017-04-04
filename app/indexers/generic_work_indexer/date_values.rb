# Takes date metadata from a GenericWork, expands it into
# an array of integer years to be used to fill an int facet
# in solr for date range limit.
class GenericWorkIndexer::DateValues
  attr_reader :work
  def initialize(work)
    @work = work
  end

  def expanded_years
    []
  end
end
