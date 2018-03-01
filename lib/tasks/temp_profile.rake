require 'ruby-prof'

task :temp_profile => :environment do
  w = GenericWork.find(ENV["ID"])

  result = RubyProf.profile do
    CHF::CitableAttributes.new(w).to_csl_json
  end

  printer = RubyProf::GraphHtmlPrinter.new(result)
  file = File.open("profile.html", "w")
  printer.print(file, {})
  puts File.absolute_path(file.path)
end
