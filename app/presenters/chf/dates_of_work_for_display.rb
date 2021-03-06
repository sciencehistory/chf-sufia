module CHF
  class DatesOfWorkForDisplay

    BEFORE = "before"
    AFTER = "after"
    CENTURY = "century"
    CIRCA = "circa"
    DECADE = "decade"
    UNDATED = "Undated"

    def initialize(dates_of_work)
      @dates_for_display = dates_of_work.collect {|d| display_label(d)}
    end

    #Return an array of strings, each containing a formatted date.
    def display_dates
      @dates_for_display
    end

    def display_label(date_of_work)
      start_string = qualified_date(date_of_work.start,
        date_of_work.start_qualifier)
      finish_string = qualified_date(date_of_work.finish,
        date_of_work.finish_qualifier)

      if finish_string.blank?
        date_string = start_string
      else
        # careful, this is an en dash:
        date_string = [start_string, finish_string].compact.join(" – ")
      end

      if date_of_work.note.present?
        date_string = "#{date_string} (#{date_of_work.note})"
      end

      date_string
    end


    def capitalize (str)
      if str == nil
        nil
      elsif str.blank?
        str
      elsif str.length == 1
        str.capitalize
      else
        str.slice(0,1).capitalize + str.slice(1..-1)
      end
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
        int_date_value = nil
      end

      date=fix_month(date)

      if qualifier == (BEFORE) || qualifier == (AFTER) || qualifier == (CIRCA)
        "#{qualifier} #{date}"
      elsif qualifier ==  DECADE
        if int_date_value == nil or int_date_value % 10 != 0 or int_date_value % 100 == 0
          #for non-obvious decades starting in e.g. 1912 or 1800 or "way back when"
          "decade starting #{date}"
        else
          #ordinary decades (e.g. 1910s)
          "#{date}s"
        end
      elsif qualifier ==  CENTURY
        if int_date_value == nil  or int_date_value % 100 != 0
          "century starting #{date}"
        else
          "#{date}s"
        end
      elsif qualifier ==  UNDATED
        qualifier
      elsif date.present?
        date
      else
        ""
      end
    end # qualified_date
  end # class
end # module