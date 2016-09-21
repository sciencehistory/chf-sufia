require 'rails_helper'
require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

RSpec.describe 'CHF::Reports::MetadataCompletionReport' do
  # just title
  let(:depositor) { FactoryGirl.create(:depositor) }
  let(:curator) { 'jvoelkel@chemheritage.org' }
  before do
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata depositor
      f.division = 'Archives'
      f.title = ['Kettle']
      f.save!
    end
    # title and description
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata depositor
      f.division = 'Archives'
      f.title = ['Teapot']
      f.description = ['handle, spout']
      f.save!
    end
    # just description
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata depositor
      f.division = 'Archives'
      f.description = ['cataloged out of order']
      f.save!
    end
    # neither
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata depositor
      f.title = ['bears.tif']
      f.division = 'Archives'
      f.save!
    end
    # both, different division
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata depositor
      f.division = nil
      f.title = ['Toothbrush']
      f.description = ['handle, bristles']
      f.save!
    end
    # both, transferred object
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata depositor
      f.division = 'Othmer Library of Chemical History'
      f.title = ['Book of some kind']
      f.description = ['useful for historical research']
      f.permissions << Hydra::AccessControls::Permission.new(type: 'person', name: curator, access: 'edit')
      f.save!
    end
  end

  it 'counts completed objects' do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    report.write
    expect(report.have_titles[:archives]).to eq 2
    expect(report.complete[:archives]).to eq 1
    expect(report.totals[:archives]).to eq 4
    expect(report.totals[:library]).to eq 0
    expect(report.totals[:rare_books]).to eq 1
  end

  it 'calculates percentages' do
    report = CHF::Reports::MetadataCompletionReport.new
    expect(report.percent(1, 4)).to eq 25
  end

end
