require 'rails_helper'
require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

RSpec.describe 'CHF::Reports::MetadataCompletionReport' do
  # just title
  let(:f5) do
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata 'user@example.com'
      w.division = 'Archives'
      w.title = ['Kettle']
      w.save!
    end
  end
  # title and description
  let(:f1) do
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata 'user@example.com'
      w.division = 'Archives'
      w.title = ['Teapot']
      w.description = ['handle, spout']
      w.save!
    end
  end
  # just description
  let(:f2) do
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata 'user@example.com'
      w.division = 'Archives'
      w.description = ['cataloged out of order']
      w.title = ['bunnies.tif']
      w.save!
    end
  end
  # neither
  let(:f3) do
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata 'user@example.com'
      w.title = ['bears.tif']
      w.division = 'Archives'
      w.save!
    end
  end
  # both, different division
  let(:f4) do
    GenericWork.new.tap do |w|
      w.apply_depositor_metadata 'user@example.com'
      w.division = 'Museum'
      w.title = ['Toothbrush']
      w.description = ['handle, bristles']
      w.save!
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
