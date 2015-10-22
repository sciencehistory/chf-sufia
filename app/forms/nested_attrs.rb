module NestedAttrs
  extend ActiveSupport::Concern

  module ClassMethods
    def build_permitted_params
      permitted = super
      permitted << { date_of_work_attributes: permitted_time_span_params }
      permitted << { inscription_attributes: permitted_inscription_params }
      permitted
    end

    def permitted_time_span_params
      [ :id, :_destroy, :start, :start_qualifier, :finish, :finish_qualifier, :note ]
      # tests break when I use this nested structure which I see in other code bases
      #   (probably related to the fact that they are using multivalued fields)
      #[ :id, :_destroy, {
      #  :start => nil, :start_qualifier => nil, :finish => nil, :finish_qualifier => nil, :note => nil
      #}]
    end

    def permitted_inscription_params
      [ :id, :_destroy, :location, :text ]
    end

  end

end
