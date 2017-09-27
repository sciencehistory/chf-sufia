module Blacklight
  module Rendering
    # The field rendering pipeline
    #
    # This is a REPLACEMENT of stock blacklight class, not a re-open of class,
    # but total replacement.
    #
    # To give us:
    # 1) Customizable operations from Blacklight master (possibly to be in future 7.x)?
    #      https://github.com/projectblacklight/blacklight/blob/b2f7a223f648498658deba705fb5debe66e669dd/app/presenters/blacklight/rendering/pipeline.rb
    #
    # 2) Options that can be passed in to trigger certain customization of the pipeline:
    #
    #       join_type: :sentence (default), :separator (just commas usually), or :list (a <ul>)
    #       search_type: TO BE DONE, NOT YET. facet or straight search.
    #
    # 3) Use our custom ChfLinkToFacet instead of LinkToFacet step, which fixes it's own issues.
    class Pipeline
      class_attribute :operations

      # The ordered list of pipeline operations
      self.operations = [HelperMethod, ChfLinkToFacet, Microdata, Join]

      def initialize(values, config, document, context, options)
        @values = values
        @config = config
        @document = document
        @context = context
        @options = options

        self.operations = [HelperMethod, ChfLinkToFacet, Microdata]
        self.operations << case options[:join_type]
          when :sentence, nil
            Join
          when :separator
            SeparatorJoin
          when :list
            ListJoin
          else
            raise ArgumentError, "unrecognized join_type: '#{options[:join_type]}'"
          end
      end

      attr_reader :values, :config, :document, :context, :options

      def self.render(values, config, document, context, options)
        new(values, config, document, context, options).render
      end

      def render
        first, *rest = *stack
        first.new(values, config, document, context, options, rest).render
      end

      private

      # Ordered list of operations, Terminator must be at the end.
      def stack
        operations + [Terminator]
      end

      # Added by us, not upstream
      class SeparatorJoin < AbstractStep
        include ActionView::Helpers::OutputSafetyHelper

        def render
          return "" unless values.present?

          separator = options[:separator] || I18n.t("support.array.words_connector") || ", "
          separated_values = values.zip([separator] * (values.size - 1)).flatten
          next_step(
            safe_join(separated_values)
          )
        end
      end

      # Added by us, not upstream
      class ListJoin < AbstractStep
        include ActionView::Helpers::OutputSafetyHelper

        def render
          return "" unless values.present?
          list_values = values.collect { |v| context.content_tag("li", v)}
          next_step(
            safe_join(["<ul>".html_safe] + list_values + ["</ul>".html_safe])
          )
        end

      end


    end
  end
end
