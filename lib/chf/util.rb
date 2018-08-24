module CHF
  # just some one-off static utility methods
  module Util

    # IE "application/pdf" => "PDF". For now we do it kind of roughly.
    # Returns nil if doesn't know how to do it.
    def self.humanized_content_type(content_type)
      mime_obj = Mime::Type.lookup(content_type)
      return nil unless mime_obj

      mime_obj.symbol.to_s.upcase
    end
  end
end
