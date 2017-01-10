# frozen_string_literal: true
module Features
  module BatchEditActions
    def fill_in_batch_edit_field(id, opts = {})
      within "#form_#{id}" do
        fill_in "batch_edit_item_#{id}", with: opts.fetch(:with, "NEW #{id}")
        click_button "#{id}_save"
      end
      within "#form_#{id}" do
        sleep 0.1 until page.text.include?('Changes Saved')
        expect(page).to have_content 'Changes Saved', wait: Capybara.default_max_wait_time * 4
      end
    end

    def batch_edit_fields
      [
        "identifier", "admin_note", "resource_type", "subject", :language, "related_url",
        "artist", "author", "addressee", "creator_of_work", "contributor", "engraver",
        "interviewee", "interviewer", "manufacturer", "photographer", "printer_of_plates",
        "publisher", "genre_string", "medium", "extent", "description",
        "series_arrangement", "rights"
      ]
    end
  end
end

RSpec.configure do |config|
  config.include Features::BatchEditActions, type: :feature
end
