module CHF
  class DateHelper
    def initialize(json_arr)
      @time_span_arr ||= begin
        (json_arr || []).collect do |json|
          TimeSpanForDisplay.new.from_json(json)
        end
      end
    end
    def display_array
      @time_span_arr.map { |ts| ts.display_label  }
    end
  end
end