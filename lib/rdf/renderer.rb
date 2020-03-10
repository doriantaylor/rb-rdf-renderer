require 'rdf/renderer/version'
require 'rdf'

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

  # Coerce an Accept-* header into a hash where the keys are stripped
  # lowercase strings and the values are floating-point numbers
  # between 0 and 1. Missing q-values are given a 1 (according to
  # spec); non-numeric (ie malformed) values are given a 0, and values
  # less than 0 or greater than 1 are clipped.
  #
  # @param header [String,Symbol,Hash] the header
  # @return [Hash] of the form +{ 'key' => 1.0 }+
  def coerce_accept header
    # coerce legitimate non-hash objects
    header = header.to_s if header.is_a? Symbol

    if header.is_a? String
      header = header.strip.split(/\s*,+\s*/).map do |component|
        # key;param=value;param=value etc
        key, *params = component.split(/\s*;+\s*/)
        params = params.map do |val|
          k, v = val.split(/\s*=+\s*/, 2)
          [k.strip.downcase.to_sym, v]
        end.to_h
        [key, params]
      end.to_h
    end

    raise ArgumentError,
      "header must be a Symbol, String, or Hash, not #{header.class}" unless
      header.is_a? Hash

    # now header is guaranteed to be a hash
    header.map do |k, v|
      # the value going in needs to be a scalar or a hash containing
      # :q => Numeric
      case v
      when Hash
        # make sure the keys are symbols
        v.transform_keys! { |p| p.to_s.strip.downcase.to_sym }
        v = v[:q] || 1
      when Numeric then nil
      else v = v.to_s # otherwise turn it into a string and try your luck
      end

      # 'NaN'.to_f == 0.0
      v = v.to_f
      v = 1.0 if v > 1.0
      v = 0.0 if v < 0.0

      # make sure the keys are lowercase strings
      [k.to_s.strip.downcase, v]
    end.to_h
  end

  def render_html struct
  end

  def render_jsonld struct
  end

  # note that unlike the others this takes a repo not a struct
  def render_writer struct, type
    # recompose the struct back to a repo

    # return the writer or maybe a proc i dunno
  end

  public

  # Initialize the repository
  def initialize repo: nil, prefixes: {}, fresnel: [], rewriter: nil
    @repo = repo || RDF::Repository.new
  end

  # Render the subject as either (X)HTML+RDFa or JSON-LD. Optionally
  # accepts type and language
  #
  # @param subject [RDF::Resource] the subject to render
  # @param repo  [RDF::Repository] Override the default repository
  # @param graph [RDF::Resource] the context graph, if applicable
  # @param type  [String,Hash,nil] either a single type or an +Accept:+ header
  # @param language [Symbol,String,Hash,nil] either a single language
  #  or an +Accept-Langugage:+ header, either as a string or
  #  decomposed into a +Hash+
  # @param rewriter [#call,nil] an optional URI rewriter
  # @return [Nokogiri::XML::Document,Nokogiri::HTML::Document,Hash]
  #  either an XHTML document, an HTML document, or a JSON-LD hash.
  def render subject,
      repo: nil, graph: nil, type: nil, language: nil, rewriter: nil
    repo ||= @repo
    # process type
    # process language

    # retrieve forward and reverse structs from repo
    # retrieve yr mom
  end

  alias_method :call, :render
end
