# frozen_string_literal: true
module Kadmin
  module Navigation
    # A navigation link for use with the navbar items
    class Link
      include Kadmin::Presentable

      # @return [String] text of the link
      attr_reader :text

      # @return [String, URL] path/URL for the given link
      attr_reader :path

      # @return [Array<String>] list of additional CSS classes
      attr_reader :css_classes

      def initialize(text:, path:, css_classes: [])
        @text = text.freeze
        @path = path.freeze
        @css_classes = Array.wrap(css_classes).freeze
      end

      # Generates HTML for use in the main Kadmin layout to build the navigation sidebar
      class Presenter < Kadmin::Presenter
        # Generates HTML to present the section
        # @param [ActiveView::Base] view_context the context to present the section in
        # @return [ActiveSupport::SafeBuffer] safe HTML to display
        def generate(**)
          css_classes = self.css_classes
          css_classes = self.css_classes.dup << 'active' if @view.controller.request.path == @path
          contents = @view.link_to(self.text, self.path)

          return %(<li class="#{css_classes.join(' ')}">#{contents}</li>).html_safe
        end
      end
    end
  end
end
