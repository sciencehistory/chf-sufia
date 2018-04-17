module CHF
  # This class allows us to have more control over the presentation
  # of dates on the search result and item view pages.
  # app/presenters/chf/time_span_for_display.rb subclasses and
  # cannibalizes model app/models/time_span.rb for its
  # date display methods.
  class TimeSpanForDisplay < ActiveFedora::Base::TimeSpan
    def display_label
      start_string = qualified_date(fix_month(start), start_qualifier)
      finish_string = qualified_date(fix_month(finish), finish_qualifier)
      date_string = [start_string, finish_string].compact.join(" – ") # en dash
      if note.present?
        date_string << " (#{note})"
      end
      date_string.slice(0,1).capitalize + date_string.slice(1..-1)
    end

    def fix_month(date_given)
      return date_given if date_given.blank?
      ymd_arr = date_given.split("-")
      return date_given if ymd_arr.length < 2
      month_index = ymd_arr[1].to_i
      return date_given if month_index == 0
      month_str = Date::ABBR_MONTHNAMES[month_index]
      ymd_arr [1] = month_str
      return ymd_arr.join('-')
    end

    def qualified_date(date, qualifier)
      begin
        int_date_value = Integer(date)
      rescue
        return super
      end

      if qualifier ==  DECADE
        if int_date_value % 10 != 0 or int_date_value % 100 == 0
          #for non-obvious decades starting in e.g. 1912 or 1800:
          "decade starting #{date}"
        else
          #ordinary decades (e.g. 1910s)
          "#{date}s"
        end

      elsif qualifier ==  CENTURY
        if int_date_value % 100 != 0
          "century starting #{date}"
        else
          "#{date}s"
        end

      else
        super
      end
    end # qualified_date
  end
end