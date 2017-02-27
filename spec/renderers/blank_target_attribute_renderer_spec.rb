require 'rails_helper'
require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml/rspec_matchers'

RSpec.describe BlankTargetAttributeRenderer do
  let(:field) { :related_url }
  let(:renderer) { described_class.new(field, ['http://www.example.com']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) {
      "<tr><th>Related url</th>\n" \
        "<td><ul class=\"tabular\"><li class=\"attribute related_url\"><a target=\"_blank\" href=\"http://www.example.com\"><span class=\"glyphicon glyphicon-new-window\"></span>&nbsp;http://www.example.com</a></li></ul></td>\n" \
        "</tr>"
    }
    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
