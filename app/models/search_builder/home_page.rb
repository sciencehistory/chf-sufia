class SearchBuilder

  # Restricts to only things a non-logged in user can see, but unlike the default
  # `Sufia::HomepageSearchBuilder` does _not_ restrict to just works, includes
  # anything that is visible in ordinary search results.
  class HomePage < SearchBuilder

    # Override to always return the null-user ability, no matter who is logged
    # in.
    def current_ability
      Ability.new(nil)
    end
  end
end
