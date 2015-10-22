require 'rails_helper'

RSpec.describe "records/show_fields/_inscription.html.erb" do
  it "should display the inscription location and text" do
    file = object_double(GenericFile.new)
    allow(file).to receive(:[]).with(:inscription).and_return (
      [
        {
          "id" => "testid",
          "location" => ["in a place"],
          "text" => ["someone notes a thing"]
        }
      ]
    )
    record = GenericFilePresenter.new(file)
    
    render :partial => "records/show_fields/inscription", :locals => {:record => record}

    expect(rendered).to have_content "(in a place) \"someone notes a thing\""
  end
end
