class Ability
  include Hydra::Ability

  include CurationConcerns::Ability
  include Sufia::Ability

  self.ability_logic += [:everyone_can_create_curation_concerns]

  # Define any customized permissions here.
  def custom_permissions
    if current_user.admin?
      # Role management
      # don't allow :destroy, :edit, :create
      #  - destroy adds a 'delete' button that
      #    - could be clicked accidentally
      #    - would be very infrequently used (if ever)
      #  - implications of edit are unclear for associated actions
      #  - create is meaningless without associating actions which happens in code.
      can [:read, :add_user, :remove_user], Role
      can [:manage], SolrDocument
    else
      # prohibit object destruction
      cannot [:destroy], ActiveFedora::Base
      # used by views where solr_document stands in for AF object
      cannot [:destroy], SolrDocument
    end
  end

end
