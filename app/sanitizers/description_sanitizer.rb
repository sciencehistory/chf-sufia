
# Based on code in rails_html_sanitizer, which doesn't have as nice
# an API as we'd like, this is way weirder than expected!
#
# only allow good html tags, and good attributes on those tags --
# no do-it-yourself style or class etc.
class DescriptionSanitizer < Rails::Html::Sanitizer
  class_attribute :allowed_tags
  self.allowed_tags = %w{b i cite a}

  class_attribute :allowed_attributes
  self.allowed_attributes = %w{href}

  attr_reader :scrubber

  def initialize(add_target_blank: false)
    @add_target_blank = add_target_blank

    @scrubber = Rails::Html::PermitScrubber.new.tap do |scrubber|
      scrubber.tags = allowed_tags
      scrubber.attributes = allowed_attributes
    end

    @link_blank_target_scrubber = Loofah::Scrubber.new do |node|
      if node.name == "a"
        node['target'] = '_blank'
      end
    end
  end

  def sanitize(html, options = {})
    return unless html
    return html if html.empty?

    loofah_fragment = Loofah.fragment(html)
    loofah_fragment.scrub!(@scrubber)

    if add_target_blank?
      loofah_fragment.scrub!(@link_blank_target_scrubber)
    end

    properly_encode(loofah_fragment, encoding: 'UTF-8')
  end

  def add_target_blank?
    @add_target_blank
  end
end
