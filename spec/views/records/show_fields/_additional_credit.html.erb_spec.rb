require 'rails_helper'

RSpec.describe "records/show_fields/_additional_credit.html.erb" do
  it "should display the additional credit label" do
    file = GenericFile.new
    file.apply_depositor_metadata('test')
    file.additional_credit_attributes = [{role: 'photographer', name: 'Tom Thumb'}]
    file.save
    record = GenericFilePresenter.new(file)

    render :partial => "records/show_fields/additional_credit", :locals => {:record => record}

    expect(rendered).to have_content "Photographed by Tom Thumb"
  end
end
