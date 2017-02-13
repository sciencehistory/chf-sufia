require 'spec_helper'

RSpec.describe CurationConcerns::Renderers::AttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Jessica', 'Bob']) }
  let(:yml_path) { File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures', 'locales', '*.{rb,yml}') }
  before do
    I18n.load_path += Dir[File.join(yml_path)]
    I18n.reload!
  end
  after do
    I18n.load_path -= Dir[File.join(yml_path)]
    I18n.reload!
  end

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    context 'When fields are non-alphabetically ordered' do
      let(:tr_content) {
        "<tr><th>Name</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute name\">Bob</li>\n" \
         "<li class=\"attribute name\">Jessica</li>\n" \
         "</ul></td></tr>"
      }
      it 'sorts them' do
        expect(subject).to be_equivalent_to(expected).respecting_element_order
      end
    end

  end
end
