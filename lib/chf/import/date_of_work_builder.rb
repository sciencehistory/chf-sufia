module Chf
  module Import
    class DateOfWorkBuilder

      # Build DateOfWorks on a Work based on json metadata
      #
      #  @param Array[hash] json_dows An array of hashes with the below keys
      #  @option :start
      #  @option :start_qualifier
      #  @option :finish
      #  @option :finish_qualifier
      #  @option :note
      #  @option :id       - not used - Id for the permissions is generated
      def build(work, json_dows)
        dows = Array.new
        json_dows.each do |dow|
          dows << create(dow)
        end
        work.date_of_work = dows if !dows.empty?
      end

      private

        def create(dow_hash)
          dow = DateOfWork.new

          dow.start = dow_hash[:start]
          dow.finish = dow_hash[:finish]
          dow.start_qualifier = dow_hash[:start_qualifier]
          dow.finish_qualifier = dow_hash[:finish_qualifier]
          dow.note = dow_hash[:note]
          dow
        end

    end
  end
end
