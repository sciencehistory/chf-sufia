require 'rails_helper'

describe Chf::Import::DateOfWorkBuilder do
  let(:builder) { described_class.new }
  let(:date_of_work) do
    [
      { "id": "h989r331m",
        "start": "2000",
        "finish": "2016",
        "start_qualifier": "after",
        "finish_qualifier": "before",
        "note": "not sure exactly when" }
    ]
  end
  let(:work) { FactoryGirl.create(:generic_work) }
  before { builder.build(work, date_of_work) }

  it 'creates a DateOfWork object' do
    expect(work.date_of_work.first).to be_a DateOfWork
  end

  it 'has the right data' do
    expect(work.date_of_work.first.id).not_to eq 'h989r331m'
    expect(work.date_of_work.first.start).to eq '2000'
    expect(work.date_of_work.first.finish).to eq '2016'
    expect(work.date_of_work.first.start_qualifier).to eq 'after'
    expect(work.date_of_work.first.finish_qualifier).to eq 'before'
    expect(work.date_of_work.first.note).to eq 'not sure exactly when'
  end
end
