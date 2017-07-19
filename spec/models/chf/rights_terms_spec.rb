require 'spec_helper'

describe CHF::RightsTerms do
  describe "for standard id" do
    let(:id) { "http://rightsstatements.org/vocab/InC/1.0/" }

    it "can look up category" do
      expect(described_class.category_for(id)).to be_present
    end

    it "can look up short_label_html_for" do
      expect(described_class.short_label_html_for(id)).to be_present
    end
  end
end
