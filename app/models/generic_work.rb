# Generated via
#  `rails generate curation_concerns:work GenericWork`
class GenericWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include Sufia::WorkBehavior
  include GenericMetadata

  self.human_readable_type = 'Work'
  self.indexer = CHF::GenericWorkIndexer

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  validate :legal_representative_id, :legal_thumbnail_id

  # If this work is a representative for some OTHER work, changes to it's
  # representative requires reindexing that parent, so some expensive work
  # is sadly needed.
  #
  # We want to try to do this expensive thing only do this if representative has actually
  # changed, but hard to count on getting changes in various circumstances, forwards-compatibly.
  # We try, but if both changes and previous_changes are blank, we figure
  # we better do it anyway. Not totally sure if this catching the right things,
  # but it seems to work not missing anything.
  #
  # This code goes with custom code in indexer to index representative_width,
  # representative_height, and representative_original_file_id.
  def update_index(*args)
    super.tap do
      if self.changes.keys.include?("representative_id") ||
         self.previous_changes.keys.include?("representative_id") ||
         (self.changes.blank? && self.previous_changes.blank?)
        GenericWork.where(GenericWork.reflections[:representative_id].solr_key => self.id).each do |parent_work|
          parent_work.update_index
        end
      end
    end
  end

  protected

  def legal_representative_id
    return if representative_id.nil?
    # This is known to cause problems with curation_concerns@608b02916cd7,
    # doesn't make sense to have a representative that's not in members.
    # But happened at least once anyway. Try to prevent it.
    unless ordered_member_ids.include?(representative_id) && member_ids.include?(representative_id)
      errors.add(:representative_id, "must be included in members and ordered_members")
    end
  end

  def legal_thumbnail_id
    return if thumbnail_id.nil?
    # While this is NOT known to cause problems with curation_concerns@608b02916cd7,
    # it does seem to violate the intentional semantics, so we'll prevent it.
    unless ordered_member_ids.include?(thumbnail_id) && member_ids.include?(thumbnail_id)
      errors.add(:thumbnail_id, "must be included in members and ordered_members")
    end
  end
end
