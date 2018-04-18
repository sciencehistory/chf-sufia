require 'rails_helper'
def populate_date ( st, fi, stq, fiq, n)
  date_of_work = DateOfWork.new()
  date_of_work.start=st
  date_of_work.finish=fi
  date_of_work.start_qualifier=stq
  date_of_work.finish_qualifier=fiq
  date_of_work.note=n
  date_of_work
end
RSpec.describe CurationConcerns::GenericWorkShowPresenter do
    let(:solr_document) { SolrDocument.new() }
    let(:ability) { double "Ability" }
    let(:presenter) { described_class.new(solr_document, ability) }

    describe 'date objects for display' do
      it 'correctly displays the date strings given a set of date objects' do
        date_array = [
          #             start         finish               start_q        finish_q  note
          populate_date("1800",       "",            "",          "",       ""      ),
          populate_date(nil,          nil,           nil,         nil,      nil     ),
          populate_date(nil,          nil,           nil,         nil,      "circa" ),
          populate_date("1912",       "",            "decade",    "",       ""      ),
          populate_date("1780",       "",            "decade",    "",       ""      ),
          populate_date("way back when",  "",        "decade",    "",       ""      ),
          populate_date("1912",       "",            "century",   "",       ""      ),
          populate_date("1780",       "",            "century",   "",       ""      ),
          populate_date("way back when",  "",        "century",   "",       ""      ),
          populate_date("1700",       "",            "century",   "",       ""      ),
          populate_date("the end of time",   "",     "after",     "",       "For real!"),
          populate_date("the end of time",   "",     "circa",     "",       ""      ),
          populate_date("1800",       "1900",        "century",   "",       "Note 1"),
          populate_date("1800",       "1900",        "century",   "",       "Note 2"),
          populate_date("1929-01-02", "1929-01-03",  "circa",     "before", "Note 3"),
          populate_date("1872",       "1929-01-03",  "after",     "before", "Note 4"),
          populate_date("1920",       "1928-11",     "decade",    "",       "Note 5"),
        ]
        presenter.instance_variable_set(:@date_of_work_structured, date_array)
        the_display_dates = presenter.display_dates
        correct_results = [
            "1800",
            "",
            " (circa)",
            "Decade starting 1912",
            "1780s",
            "Decade starting way back when",
            "Century starting 1912",
            "Century starting 1780",
            "Century starting way back when",
            "1700s",
            "After the end of time (For real!)",
            "Circa the end of time",
            "1800s – 1900 (Note 1)",
            "1800s – 1900 (Note 2)",
            "Circa 1929-Jan-02 – before 1929-Jan-03 (Note 3)",
            "After 1872 – before 1929-Jan-03 (Note 4)",
            "1920s – 1928-Nov (Note 5)"
        ]
        correct_results.each_with_index.map { |x,i| expect(the_display_dates[i]).to eq x }
      end
    end
end
