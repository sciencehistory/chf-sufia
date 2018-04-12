module CHF
  class TimeSpanForDisplay < ActiveFedora::Base::TimeSpan
    def display_label
      start_string = qualified_date(fix_month(start), start_qualifier)
      finish_string = qualified_date(fix_month(finish), finish_qualifier)
      ndash = "\u2013".force_encoding('utf-8')
      date_string = [start_string, finish_string].compact.join(" #{ndash} ")
      if note.present?
        date_string << " (#{note})"
      end
      date_string
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
  end
end