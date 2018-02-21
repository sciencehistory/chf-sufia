# Only a 'show' action
#
# Sub-classes our custom CollectionsShowController, but with many
# overrides for our synthetic yaml-config-based "synthetic collections", ie
# "featured topics".
#
# The overrides get messy, sorry.
class SyntheticCategoryController < CollectionsShowController
  # not quite sure what this is trying to do, but it's inapplicable for our
  # synthetic categories
  skip_before_action :enforce_show_permissions

  protected

  # override to no-op, breadcrumbs don't work here
  def build_breadcrumbs
  end

  def presenter
    @presenter ||= CHF::SyntheticCategory.from_slug(params[:id]).tap do |cat|
      if cat.nil?
        raise ActionController::RoutingError.new("No SyntheticCategory matches `#{params[:id]}`")
      end
    end
  end
  helper_method :presenter


  # Override searchbuilder to limit to things in our synthetic category
  def search_builder
    @search_builder ||= SearchBuilder.new(self).tap { |sb| sb.synthetic_category_force = presenter.category_key }
  end


  def total_count
    # improvement, cache somewhere?
    @total_count ||= repository.search( search_builder.with(params.merge(rows: 0)).query).total
  end
  helper_method :total_count



end
