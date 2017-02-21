module CHF
  module Reports
    class MetadataCompletionReport

      attr_reader :lookup, :published, :full, :totals

      def initialize
        @lookup = {
          Rails.configuration.divisions[0] => :archives,
          Rails.configuration.divisions[1] => :oral,
          Rails.configuration.divisions[2] => :museum,
          Rails.configuration.divisions[3] => :library,
          "Rare Books" => :rare_books,
          "" => :unknown
        }
        @published = lookup.values.inject({}) { |h, k| h.merge({k => 0}) }
        @full = published.deep_dup
        @totals = published.deep_dup
        @rb_curator = 'jvoelkel@chemheritage.org'
      end

      def run
        i = 0
        total = GenericWork.count
        GenericWork.all.find_each do |w|
          i += 1
          puts "Analyzing work #{i} of #{total}: #{w.id} #{w.title.first}"

          division = w.division.nil? ? "" : w.division
          if lookup[division] == :library
            # figure out who can edit
            can_edit = []
            w.permissions.each do |perm|
              can_edit << perm.agent_name if perm.access == "edit"
            end
            division = "Rare Books" if can_edit.include? @rb_curator
          end
          @totals[lookup[division]] = totals[lookup[division]] + 1
          if is_published(w)
            @published[lookup[division]] = published[lookup[division]] + 1
            if has_description(w)
              @full[lookup[division]] = full[lookup[division]] + 1
            end
          end
        end
      end

      def write
        lookup.each do |k, v|
          k = k.empty? ? "Uncategorized" : k
          write_line(k, published[v], totals[v], "records are published")
          write_line(k, full[v], totals[v], "records are published with descriptions")
        end
        write_line('All divisions', published.values.reduce(0, :+), totals.values.reduce(0, :+), "records are published")
        write_line('All divisions', full.values.reduce(0, :+), totals.values.reduce(0, :+), "records are published with descriptions")
      end

      def write_line(category, numerator, denominator, text)
          puts "#{category}: #{numerator} / #{denominator} (#{percent(numerator, denominator)}%) #{text}"
      end

      def percent(num, denom)
        # special case for denom == 0
        return 100 if num == denom
        return (num.fdiv(denom)  * 100).to_i
      end

      # return true if the visibility is open/public
      def is_published(w)
        return w.visibility.eql? 'open'
      end

      def has_description(w)
        return !(w.description.empty? or w.description.first.empty?)
      end

    end
  end
end
