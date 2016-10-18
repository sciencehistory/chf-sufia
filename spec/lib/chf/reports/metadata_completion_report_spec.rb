require 'rails_helper'
require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

RSpec.describe 'CHF::Reports::MetadataCompletionReport' do
  let(:depositor) { FactoryGirl.create(:depositor) }
  let(:curator) { 'jvoelkel@chemheritage.org' }
  # just title
  before do
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Archives'
      w.title = ['Kettle']
      w.save!
    end
  # title and description
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Archives'
      w.title = ['Teapot']
      w.description = ['handle, spout']
      w.save!
    end
  # just description
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Archives'
      w.description = ['cataloged out of order']
      w.title = ['bunnies.tif']
      w.save!
    end
  # neither
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.title = ['bears.tif']
      w.division = 'Archives'
      w.save!
    end
  # both, different division
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = nil
      w.title = ['Toothbrush']
      w.description = ['handle, bristles']
      w.save!
    end
    # both, transferred object
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Othmer Library of Chemical History'
      w.title = ['Book of some kind']
      w.description = ['useful for historical research']
      w.permissions = [Hydra::AccessControls::Permission.new(type: 'person', name: curator, access: 'edit'),
                       Hydra::AccessControls::Permission.new(type: 'person', name: depositor, access: 'edit')]
      w.save!
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
