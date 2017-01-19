module CHF
  module Reports
    class DataCheckReport

      attr_reader :accum

      def initialize
        @accum = { sarah: [], hillary: [], ashley: [] }
      end

      def run
        i = 0
        total = GenericWork.count
        GenericWork.all.find_each do |w|
          i += 1
          puts "Analyzing work #{i} of #{total}: #{w.id} #{w.title.first}"

          if w.rights.empty?
            if w.edit_users.include?('hkativa@chemheritage.org')
              @accum[:hillary] << w
            end

            if w.edit_users.include?('aaugustyniak@chemheritage.org')
              @accum[:ashley] << w
            end

            if w.visibility == 'open' && ['mmiller@chemheritage.org', 'snewhouse@chemheritage.org'].include?(w.depositor)
              @accum[:sarah] << w
            end
          end

        end

      end

      def write
        @accum.each do |name, vals|
          puts "#{name}'s works without rights info: #{vals.count}"
          vals.each do |v|
            puts "  #{v.id} #{v.title}"
          end
        end
      end

    end
  end
end
