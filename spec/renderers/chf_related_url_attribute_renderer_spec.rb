require 'rails_helper'
require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml/rspec_matchers'

RSpec.describe ChfRelatedUrlAttributeRenderer do
  let(:field) { :related_url }
  let(:renderer) { described_class.new(field, ['http://www.example.com/something']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) {
      "<tr><th>Related URL</th>" \
        "<td><ul class=\"tabular\"><li class=\"attribute related_url\"><a target=\"_blank\" href=\"http://www.example.com/something\"><span class=\"glyphicon glyphicon-new-window\"></span>\u00A0www.example.com/...</a></li></ul></td>" \
        "</tr>"
    }
    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
