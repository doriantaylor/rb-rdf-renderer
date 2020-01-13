require 'rdf/renderer/version'

class RDF::Renderer::Fresnel
  # We will currently not be implementing SPARQL or FSL selectors.

  # We *will* however need some mechanism for describing reverse
  # properties.

  # Initialize a Fresnel ensemble by giving it an RDF::Queryable to
  # extract lenses, formats etc. from.

  def initialize repo
    rehash repo
  end

  # Rehash the Fresnel ensemble, e.g. when the lenses/formats
  # themselves are modified.
  def rehash repo
  end

  # Select a lens to apply to the subject
  def select subject, repo: nil, group: nil, default: false, label: false
    # first attempt to match the subject

    # then attempt to match the subject's class
  end

  class Lens
    # The Fresnel Lens is responsible for matching subjects to a set
    # of directives, principally about which properties to show and in
    # what order.

    # The essential components are a pair of lists of properties to
    # show and hide, respectively.

    # The elements of each list contain (are coerced into) property
    # descriptions that further instruct what to do.

    # The other essential part is the set of matching criteria, which
    # could match a class or specific subject (or both); indeed
    # multiples of either.

    # we also have flags for whether the lens is default or label
    # (could theoretically be both)

    # * what group(s) does the lens belong to
    # * what explicit format(s)/group(s) to use
  end

  class PropertyDescription
    # The property description
  end

  class Format
  end

  class Group
  end
end
