module Sufia
  # We've overrideen this to do NOTHING, cause we take care of it in our custom
  # create_with_files_actor.rb. Overriding to do nothing was easier than figuring out
  # how to take it out of the 'actor stack'.
  class CreateWithRemoteFilesActor < CurationConcerns::Actors::AbstractActor
    def create(attributes)
      next_actor.create(attributes)
    end

    def update(attributes)
      next_actor.update(attributes)
    end
  end
end
