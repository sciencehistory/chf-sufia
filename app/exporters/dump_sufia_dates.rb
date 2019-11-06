# This produces a (valid) json dump of Collection, GenericWork
# and FileSet dates.

# bin/rails  runner dump_sufia_dates.rb
# cat  sufia_dates.json   |  python -m json.tool
def to_utc(some_date)
  return nil if some_date.nil?
  return some_date.utc if some_date.class == DateTime
  return DateTime.rfc2822(some_date).utc if some_date.class == String
end

progress_bar_total = FileSet.count + GenericWork.count + Collection.count
progress_bar = ProgressBar.create(total: progress_bar_total, format: "%a %t: |%B| %R/s %c/%u %p%% %e")

open('sufia_dates.json', 'w') do |f|
  f.puts '{"date_list":['
  comma = false
  [FileSet, GenericWork, Collection].each do |s|
    progress_bar.log("INFO: Starting #{s}s")
    f.puts "," if comma
    comma = false
    s.find_each do |x|
      f.puts "," if comma
      comma = true
      tempHash = {
        date_modified: to_utc(x.date_modified),
        date_uploaded: to_utc(x.date_uploaded),
        create_date: to_utc(x.create_date.utc),
        type: x.class.to_s,
        id: x.id
      }
      f.puts tempHash.to_json
      progress_bar.increment
    end
    progress_bar.log("INFO: Done with #{s}s")
  end
  f.puts ']}'
end