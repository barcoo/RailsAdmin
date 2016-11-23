module Kadmin
  # Base presenter class
  class Presenter < SimpleDelegator
    # @param [Object] object the object to present
    # @param [ActiveView::Base] view the view to present in; can be provided later on
    def initialize(object, view: nil)
      super(object)
      @view = view
    end

    # Renders the wrapped object into the given view
    # @param [ActiveView::Base] view optionally render in a different view
    # @param [Hash] options additional options passed to the render method
    # @return [Object] rendered representation of the wrapped object, typically a string
    def render(view: nil, **options)
      previous_view = @view
      rendered = nil

      begin
        @view = view unless view.nil?
        raise Kadmin::Presenter::NoViewContext if @view.nil?
        rendered = generate(**options)
      ensure
        @view = previous_view
      end

      return rendered
    end

    # Generates the representation of the wrapped object.
    # Should be overloaded and implemented by a concrete class.
    def generate(**)
      return "<div>#{__getobj__.inspect}</div>".html_safe
    end
    protected :generate

    class NoViewContext < Kadmin::Error
      def initialize(message = nil)
        message ||= 'cannot render without a view context'
        super(message)
      end
    end
  end
end