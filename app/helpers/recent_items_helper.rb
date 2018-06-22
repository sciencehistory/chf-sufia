# A random selection of recently modified works to display as thumbnails
# on the front page of the site.
# The same selection is shown to all users at the same time.
# The selection is reshuffled few minutes,
# and is cached for speed.
module RecentItemsHelper
  class RecentItems
    def initialize()
        @how_many_works_to_show = 6
        @how_often_to_change = 60 * 10 # ten minutes
        @how_many_works_in_bag = 15
    end

    def recent_items()
      trigger_reshuffle_if_needed()
      # First, put a bunch of eligible works into a bag.
      works_to_pick_from = bag_of_recent_items()
      # Now, pick a few of these out of the bag at random to show.
      # Reshuffle the bag every now and then.
      srand get_num()
      works_to_pick_from.sort_by{rand}[0... @how_many_works_to_show]
    end

    private
    def trigger_reshuffle_if_needed()
        if time_to_reshuffle?()
          # Fetch a new bag of recent works
          # from SOLR and reshuffle the bag
          # even if there haven't been any new works added.
          set_bag(nil) # thus forcing a new call to SOLR.
        end
    end

    # @@num is a slowly incrementing integer that changes at most every
    # how_often_to_change minutes.
    def time_to_reshuffle?()
      new_arbitrary_number = Time.now.to_i / @how_often_to_change
      if num_missing? || get_num() != new_arbitrary_number
        set_num(new_arbitrary_number)
        return true
      end
      return false
    end

    def bag_of_recent_items
      conds =  {
        'read_access_group_ssim'=>'public'
      }
      opts = {
        :rows=> @how_many_works_in_bag,
        :sort=> ["system_modified_dtsi desc"]
      }
      set_bag(GenericWork.search_with_conditions(conds, opts)) if bag_missing?
      get_bag()
    end

    # getter/setter methods for our two class variables:
    def bag_missing?()
      var_missing?(:@@bag) || (get_bag() == nil)
    end
    def set_bag (value)
      self.class.class_variable_set(:@@bag, value)
    end
    def get_bag()
      self.class.class_variable_get(:@@bag)
    end


    def num_missing?()
      var_missing?(:@@num) || (get_num() == nil)
    end
    def set_num(value)
      self.class.class_variable_set(:@@num, value)
    end
    def get_num()
      self.class.class_variable_get(:@@num)
    end

    def var_missing?(symbol)
      begin
        tmp = self.class.class_variable_get(symbol)
        defined?(tmp) != "local-variable"
      rescue
        true
      end
    end

  end #class
end #module