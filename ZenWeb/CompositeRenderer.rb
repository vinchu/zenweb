require 'ZenWeb/GenericRenderer'

=begin

= Class CompositeRenderer

Allows multiple renderers to be plugged into a single renderer.

=== Methods

=end

class CompositeRenderer < GenericRenderer

=begin

--- CompositeRenderer#new(document)

    Creates a new CompositeRenderer.

=end

  def initialize(document)
    super(document)
    @renderers = []
  end

=begin

--- CompositeRenderer#render(content)

    Renders by running all of the renderers in sequence.

=end

  def render(content)
    @renderers.each { | renderer |
      content = renderer.render(content)
    }
    return content
  end

=begin

--- CompositeRenderer#addRenderer(renderer)

    Adds renderer to the list of renderers used by this composite.

=end

  def addRenderer(renderer)
    @renderers.push(renderer)
  end

end

