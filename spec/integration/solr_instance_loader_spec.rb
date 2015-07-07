require 'rails_helper'

RSpec.describe ActiveFedora::SolrInstanceLoader do

  let (:file) { GenericFile.new(title: ['Blueberries for Sal']) }

  before do
    file.apply_depositor_metadata('depositor')
    file.date_of_work_attributes = [ {start: "2003", finish: "2015"}, { start: "2996" } ]
    file.save!
  end

  context "without a solr doc" do
    context "with context" do

      it "loads both nested attribute IDs" do
        expect(file.date_of_work_ids.count).to eq 2
        loader = ActiveFedora::SolrInstanceLoader.new(GenericFile, file.id)
        expect(loader.object.title).to eq ['Blueberries for Sal']
        expect(loader.object.date_of_work_ids.count).to eq 2
      end
    end

  end
end
