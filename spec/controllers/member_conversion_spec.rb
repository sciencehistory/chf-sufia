require 'rails_helper'

# The actual cconversion work is done in a bg job launched by the controller.
# But this test currently tests for results of that bg job too, sort of "integration" style.
# This works cause we run jobs inline in test.
# Not necessarily ideal test design, but good enough for now, we're dealing with a lot here.
RSpec.describe MemberConversionController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  let!(:collection) { FactoryGirl.create(
    :public_collection,
    members: [parent_work]
  )}

  before do
    sign_in user
  end

  before do
    allow(controller.current_ability).to receive(:can?).and_return(true)
  end

  context "a generic work with a file attached to it." do
    let(:parent_work) {  FactoryGirl.create(
      :work,
      :fake_public_image,
      creator: ["Fred"],
      title: ["abc"],
      language: ['en'],
      id: 'parent123'
    )}

    it "promotes a fileset to a child work" do
      # Note that a member fileset was already created,
      # conveniently enough, when we created the parent work.

      file_set = parent_work.ordered_members.to_a.first
      post :to_child_work, params: {  parentid: parent_work.id, filesetid: file_set.id }
      parent_work.reload
      collection.reload

      expect(GenericWork.all.to_a.count).to eq 2
      expect(parent_work.members.to_a.count).to eq 1
      expect(parent_work.ordered_members.to_a.count).to eq 1
      new_child_work = parent_work.members.first
      expect(new_child_work.class.name ).to eq "GenericWork"
      expect(response).to be_redirect
      expect(parent_work.thumbnail_id).to eq  new_child_work.id
      expect(parent_work.representative_id).to eq  new_child_work.id

      # the new child work should inherit its collection from its parent.
      expect(collection.members.to_a.count).to eq 2
      expect(collection.members.to_a).to include parent_work
      expect(collection.members.to_a).to include new_child_work

      # all parent's permissions should be transferred to the new child work.
      # Otherwise stated, if you subtract the new child's permissions
      # from those of the parent, you should get an empty set.
      expect(
        (
          parent_work   .permissions.map(&:to_hash) -
          new_child_work.permissions.map(&:to_hash)
         ).count
      ).to eq 0

      # all the garden-variety metadata should get copied as well, of course.
      attrs_to_copy = parent_work.attributes.sort.map { |a| a[0] }
      attrs_to_copy -= ['id', "title", 'lease_id', 'embargo_id', 'head', 'tail',
        'access_control_id', 'thumbnail_id', 'representative_id' ]
      attrs_to_copy.each do |attr|
        expect(parent_work[attr]).to eq new_child_work[attr]
      end

      # However, the new child work's title should come from the fileset:
      expect(new_child_work.title).to eq ["sample.jpg"]
    end
  end

  context "a work with a child work attached to it" do
    let(:child_work) { FactoryGirl.create(
      :work,
      :fake_public_image,
      creator: ["Fred"],
      title: ["abc"],
      language: ['en'],
      id: 'child123'
    )}

    let(:parent_work) {
      FactoryGirl.create(
        :work,
        creator: ["Fred"],
        title: ["abc"],
        language: ['en'],
        id: 'parent123'
      ).tap do |work|
        work.ordered_members += [child_work]
        work.representative_id = child_work.id
        work.thumbnail_id = child_work.id
        work.save!
      end
    }

    it "replaces child work with direct fileset" do
      file_set = child_work.members.first

      post :to_fileset, params: {
        parentworkid: parent_work.id,
        childworkid: child_work.id
      }

      expect(response).to be_redirect

      parent_work.reload
      collection.reload

      # This gets rid of the child work
      expect { child_work.reload }.to raise_error(Ldp::Gone)

      #and re-attaches the fileset directly to the parent.
      expect(GenericWork.all.to_a.count).to eq 1
      expect(parent_work.members.to_a.count).to eq 1
      expect(parent_work.ordered_members.to_a.count).to eq 1
      expect(parent_work.members.first).to eq file_set
      expect(parent_work.thumbnail_id).to eq file_set.id
      expect(parent_work.representative_id).to eq file_set.id
    end
  end
end
