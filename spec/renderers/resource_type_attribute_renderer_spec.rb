require 'rails_helper'
require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml/rspec_matchers'

RSpec.describe ResourceTypeAttributeRenderer do
  let(:field) { :resource_type }
  let(:renderer) { described_class.new(field, ['http://purl.org/dc/dcmitype/MovingImage']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) {
      "<tr><th>Resource type</th>\n" \
       "<td><ul class='tabular'><li class=\"attribute resource_type\"><a href=\"http://purl.org/dc/dcmitype/MovingImage\" target=\"_blank\">Moving Image</a></li></ul></td>\n" \
       "</tr>"
    }
    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
