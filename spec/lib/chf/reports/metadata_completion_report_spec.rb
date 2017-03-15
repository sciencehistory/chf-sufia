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
      w.visibility = 'open'
      w.save!
    end
  # title and description
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Archives'
      w.title = ['Teapot']
      w.visibility = 'open'
      w.description = ['handle, spout']
      w.save!
    end
  # just description
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Archives'
      w.description = ['cataloged out of order']
      w.title = ['bunnies']
      w.visibility = 'authenticated'
      w.save!
    end
  # neither
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.title = ['bears']
      w.visibility = 'authenticated'
      w.division = 'Archives'
      w.save!
    end
  # both, different division
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = nil
      w.title = ['Toothbrush']
      w.visibility = 'open'
      w.description = ['handle, bristles']
      w.save!
    end
    # both, transferred object
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata depositor
      w.division = 'Library'
      w.title = ['Book of some kind']
      w.visibility = 'open'
      w.description = ['useful for historical research']
      w.permissions = [Hydra::AccessControls::Permission.new(type: 'person', name: curator, access: 'edit'),
                       Hydra::AccessControls::Permission.new(type: 'person', name: depositor, access: 'edit')]
      w.save!
    end
  end

  it 'counts completed objects' do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    expect(report.published[:archives]).to eq 2
    expect(report.full[:archives]).to eq 1
    expect(report.totals[:archives]).to eq 4
    expect(report.totals[:library]).to eq 0
    expect(report.totals[:rare_books]).to eq 1
    expect(report.get_output).to eq expected_output
  end

  it 'calculates percentages' do
    report = CHF::Reports::MetadataCompletionReport.new
    expect(report.percent(1, 4)).to eq 25
  end

  def expected_output()
    "Archives: 2 / 4 (50%) records are published\n" +
    "Archives: 1 / 4 (25%) records are published with descriptions\n" +
    "Center for Oral History: 0 / 0 (100%) records are published\n" +
    "Center for Oral History: 0 / 0 (100%) records are published with descriptions\n" +
    "Museum: 0 / 0 (100%) records are published\n" +
    "Museum: 0 / 0 (100%) records are published with descriptions\n" +
    "Library: 0 / 0 (100%) records are published\n" +
    "Library: 0 / 0 (100%) records are published with descriptions\n" +
    "Rare Books: 0 / 1 (0%) records are published\n" +
    "Rare Books: 0 / 1 (0%) records are published with descriptions\n" +
    "Uncategorized: 1 / 1 (100%) records are published\n" +
    "Uncategorized: 1 / 1 (100%) records are published with descriptions\n" +
    "All divisions: 3 / 6 (50%) records are published\n" +
    "All divisions: 2 / 6 (33%) records are published with descriptions"
  end

end
