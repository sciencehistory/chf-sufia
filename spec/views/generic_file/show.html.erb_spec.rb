require 'rails_helper'

RSpec.describe 'generic_files/show.html.erb', :type => :view do
  let (:user) { FactoryGirl.create(:depositor) }

  let(:content) do
    content = double('content', versions: [], mimeType: 'application/pdf')
  end

  let(:generic_file) do
    stub_model(GenericFile, id: '123',
      depositor: user.user_key,
      title: ['The Thinks You Can Think'],
      physical_container: 'b2|f3|v4|p5',
    )
  end

  let(:presenter) do
    GenericFilePresenter.new(generic_file)
  end

  before do
    allow(generic_file).to receive(:content).and_return(content)
    allow(controller).to receive(:current_user).and_return(user)
    allow_any_instance_of(Ability).to receive(:can?).and_return(true)
    allow(User).to receive(:find_by_user_key).with(generic_file.depositor).and_return(user)
    #allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    allow(view).to receive(:on_the_dashboard?).and_return(false)
    assign(:generic_file, generic_file)
    assign(:presenter, presenter)
    assign(:events, [])
    assign(:notify_number, 0)
  end

  describe 'physical container data' do
    before do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
    end
    it 'shows the parsed info' do
      expect(rendered).to match /Box 2, Folder 3, Volume 4, Part 5/
    end
  end

end
