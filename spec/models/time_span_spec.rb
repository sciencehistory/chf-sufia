require 'rails_helper'

RSpec.describe TimeSpan do

  describe "rdf type" do
    subject { described_class.new.type }
    it { is_expected.to eq [::RDF::URI.new('http://www.europeana.eu/schemas/edm/TimeSpan')] }
  end

  describe "#start" do
    before do
      subject.start = '1930'
    end
    it "has start" do
      expect(subject.start).to eq '1930'
    end
  end

  describe '#display_label' do
    context 'when there is a start date with no qualifier' do
      before { subject.start = '1956' }
      it 'returns the start date' do
        expect(subject.display_label).to eq '1956'
      end
    end

    context 'when there is an approximate start date' do
      before do
        subject.start = '1956'
        subject.start_qualifier = TimeSpan::CIRCA
      end
      it 'adds "circa" qualifier to the start date' do
        expect(subject.display_label).to eq 'circa 1956'
      end
    end

    context 'when the date is before a given year' do
      before do
        subject.start = '1956'
        subject.start_qualifier = TimeSpan::BEFORE
      end
      it 'adds "before" qualifier to the start date' do
        expect(subject.display_label).to eq 'before 1956'
      end
    end

    context 'when the date is after a given year' do
      before do
        subject.start = '1956'
        subject.start_qualifier = TimeSpan::AFTER
      end
      it 'adds "after" qualifier to the start date' do
        expect(subject.display_label).to eq 'after 1956'
      end
    end

    context 'when the range covers a decade' do
      before do
        subject.start = '1950'
        subject.start_qualifier = TimeSpan::DECADE
      end
      it 'adds "s" to the start date' do
        expect(subject.display_label).to eq '1950s (decade)'
      end
    end

    context 'when it is undated' do
      before do
        subject.start_qualifier = TimeSpan::UNDATED
      end
      it 'returns "Undated"' do
        expect(subject.display_label).to eq 'Undated'
      end
    end

    context 'when there is a range of dates with no qualifiers' do
      before do
        subject.start = '1956'
        subject.finish = '1958'
      end
      it 'returns the date range' do
        expect(subject.display_label).to eq '1956 - 1958'
      end
    end

    context 'when there is an approximate date range' do
      before do
        subject.start = '1956'
        subject.start_qualifier = TimeSpan::CIRCA
        subject.finish = '1958'
        subject.finish_qualifier = TimeSpan::CIRCA
      end
      it 'adds "circa" to the date range' do
        expect(subject.display_label).to eq 'circa 1956 - circa 1958'
      end
    end

    context 'when there is a bounded date range' do
      before do
        subject.start = '1956-06-28'
        subject.start_qualifier = TimeSpan::AFTER
        subject.finish = '1958-01-01'
        subject.finish_qualifier = TimeSpan::BEFORE
      end
      it 'bounds the date range' do
        expect(subject.display_label).to eq 'after 1956-06-28 - before 1958-01-01'
      end
    end

    context 'when there is a note' do
      before do
        subject.start = '1956'
        subject.note = 'weird date format'
      end
      it 'appends the note to the date range' do
        expect(subject.display_label).to eq '1956 (weird date format)'
      end
    end
  end  # display_label

  describe 'TimeSpan.start_qualifiers' do
    it 'has the expected start_qualifiers in order' do
      expect(TimeSpan.start_qualifiers).to eq(%w(before after century circa decade Undated))
    end
    it 'has the expected end_qualifiers in order' do
      expect(TimeSpan.end_qualifiers).to eq(%w(before circa))
    end
  end
end
