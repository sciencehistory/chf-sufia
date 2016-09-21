module CHF
  module Reports
    class MetadataCompletionReport

      attr_reader :lookup, :have_titles, :complete, :totals

      def initialize
        @lookup = {
          Sufia.config.divisions[0] => :archives,
          Sufia.config.divisions[1] => :oral,
          Sufia.config.divisions[2] => :museum,
          Sufia.config.divisions[3] => :library,
          "Rare Books" => :rare_books,
          "" => :unknown
        }
        @have_titles = lookup.values.inject({}) { |h, k| h.merge({k => 0}) }
        @complete = have_titles.deep_dup
        @totals = have_titles.deep_dup
        @rb_curator = 'jvoelkel@chemheritage.org'
      end

      def run
        i = 0
        total = GenericFile.count
        GenericFile.all.find_each do |f|
          i += 1
          puts "Analyzing file #{i} of #{total}: #{f.id} #{f.title.first}"

          division = f.division.nil? ? "" : f.division
          if lookup[division] == :library
            # figure out who can edit
            can_edit = []
            f.permissions.each do |perm|
              can_edit << perm.agent_name if perm.access == "edit"
            end
            division = "Rare Books" if can_edit.include? @rb_curator
          end
          @totals[lookup[division]] = totals[lookup[division]] + 1
          if has_title(f)
            @have_titles[lookup[division]] = have_titles[lookup[division]] + 1
            if has_description(f)
              @complete[lookup[division]] = complete[lookup[division]] + 1
            end
          end
        end
      end

      def write
        lookup.each do |k, v|
          k = k.empty? ? "Uncategorized" : k
          write_line(k, have_titles[v], totals[v], "records have titles")
          write_line(k, complete[v], totals[v], "records have titles and descriptions")
        end
        write_line('All divisions', have_titles.values.reduce(0, :+), totals.values.reduce(0, :+), "records have titles")
        write_line('All divisions', complete.values.reduce(0, :+), totals.values.reduce(0, :+), "records have titles and descriptions")
      end

      def write_line(category, numerator, denominator, text)
          puts "#{category}: #{numerator} / #{denominator} (#{percent(numerator, denominator)}%) #{text}"
      end

      def percent(num, denom)
        # special case for denom == 0
        return 100 if num == denom
        return (num.fdiv(denom)  * 100).to_i
      end

      # return true if the title doesn't end in .tif
      def has_title(f)
        return false if f.title.empty? or f.title.first.empty?
        match = f.title.first =~ /\.tif$/
        return match.nil?
      end

      def has_description(f)
        return !(f.description.empty? or f.description.first.empty?)
      end

    end
  end
end
