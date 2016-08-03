require 'rails_helper'
require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

RSpec.describe 'CHF::Reports::MetadataCompletionReport' do
  # just title
  let(:f5) do
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata 'user@example.com'
      f.division = 'Archives'
      f.title = ['Kettle']
      f.save!
    end
  end
  # title and description
  let(:f1) do
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata 'user@example.com'
      f.division = 'Archives'
      f.title = ['Teapot']
      f.description = ['handle, spout']
      f.save!
    end
  end
  # just description
  let(:f2) do
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata 'user@example.com'
      f.division = 'Archives'
      f.description = ['cataloged out of order']
      f.save!
    end
  end
  # neither
  let(:f3) do
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata 'user@example.com'
      f.title = ['bears.tif']
      f.division = 'Archives'
      f.save!
    end
  end
  # both, different division
  let(:f4) do
    GenericFile.new.tap do |f|
      f.apply_depositor_metadata 'user@example.com'
      f.division = 'Museum'
      f.title = ['Toothbrush']
      f.description = ['handle, bristles']
      f.save!
    end
  end

  # not sure why i'm having to do this :(
  before do
    f1.reload
    f2.reload
    f3.reload
    f4.reload
    f5.reload
  end

  it 'counts completed objects' do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    report.write
    expect(report.have_titles[:archives]).to eq 2
    expect(report.complete[:archives]).to eq 1
    expect(report.totals[:archives]).to eq 4
  end

  it 'calculates percentages' do
    report = CHF::Reports::MetadataCompletionReport.new
    expect(report.percent(1, 4)).to eq 25
  end

end
