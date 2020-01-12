require "rdf/renderer/version"

class RDF::Renderer
  # This class renders _patches_ of RDF, focused around a given
  # _subject_, into various content types:
  #
  # * (X)HTML+RDFa
  # * JSON-LD
  #
  # These are organized according to Fresnel lenses
  # It also proxies to various RDF::Writer subclasses, such as:
  #
  # * Turtle
  # * NTriples
  # * RDF/XML
  # * TRiG

  private

  public

  # 
  def initialize repo: nil, prefixes: {}, fresnel: []
  end

  # Render the subject
  def render subject, repo: nil, graph: nil, type: nil, language: nil
  end

  alias_method :call, :render
end
