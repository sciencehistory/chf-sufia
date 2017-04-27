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
      can [:manage], ActiveFedora::Base
      # used by views where solr_document stands in for AF object, to avoid
      #   retrieving from Fedora.
      can [:manage], SolrDocument
      # Hydra code passes an object id sometimes to bypass object retrieval in views.
      #   upstream code gets a permissions document from solr to check that the user
      #   can, e.g. edit / read the object in question. We don't need that step
      #   for admins.
      can [:manage], String
    end
  end

  # override this method from hydra-access-controls/lib/hydra/ability.rb
  # to remove `destroy` as an edit permission
  def edit_permissions
    can [:edit, :update], String do |id|
      test_edit(id)
    end
    can [:edit, :update], ActiveFedora::Base do |obj|
      test_edit(obj.id)
    end
    can [:edit, :update], SolrDocument do |obj|
      cache.put(obj.id, obj)
      test_edit(obj.id)
    end
  end
end
