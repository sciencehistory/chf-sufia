module Chf
  module Export
    # Convert a time_span record from a ActiveFedora:Base into a PORO so that the metadata
    #  can be exported in json format using to_json
    #
    class TimeSpanConverter
      # Create an instance of an Object containing all the metadata for the time_span
      #
      # @param [TimeSpan] time_span the time_span associated with one access record
      def initialize(time_span)
        @id = time_span.id
        @start = time_span.start.to_s
        @finish = time_span.finish.to_s
        @start_qualifier = time_span.start_qualifier.to_s
        @finish_qualifier = time_span.finish_qualifier.to_s
        @note = time_span.note.to_s
      end
    end
  end
end
