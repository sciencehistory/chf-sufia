module NestedAttrs
  extend ActiveSupport::Concern
  
  module ClassMethods
    def build_permitted_params
      permitted = super
      permitted << { date_of_work_attributes: permitted_time_span_params }
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

  end

  #  pulled from https://github.com/aic-collections/aicdams-lakeshore but
  #  not sure exactly what this is supposed to do / fix...
#  def date_of_work_attributes= attributes
#    model.date_of_work_attributes= attributes
#  end

end
