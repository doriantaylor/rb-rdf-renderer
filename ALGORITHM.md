# The Algorithm

## Given the subject, select a lens[1].

## Given the subject and the lens, assemble all properties…

> …which are to be shown and which are to be hidden.

This includes all subproperties/equivalent properties of those
asserted properties. Note that if a subproperty/equivalent property is
asserted in one list it should supersede the other.

An explicit property list in `fresnel:showProperties` implies `<#lens>
fresnel:hideProperties fresnel:allProperties .` if the latter
declaration is missing, and vice versa.

So basically a more-specific property in one bucket overrides a
less-specific property in another, with `fresnel:allProperties` being
the least specific. We can also say that `fresnel:showProperties`
scores slightly higher than `fresnel:hideProperties` because showing
properties is the entire point of a lens.

(Note: The showing/hiding of properties is purely cosmetic and should
not be considered an information security measure. If you don't want
information to show up in the result, don't put it in the input.)

(Reverse statements will need to be specified by a
`fresnel:PropertyDescription` with `<#pd> flx:reverse true .`)

At this point, we have enough to select a set of _statements_ from the
graph which we can designate as being definitely shown vs definitely
hidden. (Moreover vanilla Fresnel partitions these into two separate
sets, such that hidden properties are entirely separate from shown
ones.)

## Sort the properties[5] and the values

While the sequence of _properties_ is determined, the sequence of
_values_ is still indeterminate. (The sequence of properties implied
by `fresnel:allProperties` is _also_ indeterminate.)

We sort `fresnel:allProperties` like so:

* Round up all the properties asserted in the graph,
* Subtract the _specific_ properties asserted in both
  `fresnel:showProperties` and `fresnel:hideProperties`,
* for everything that remains, first check formats for any explicit
  `fresnel:label` values, filtering for language preferences[6],
* for the remainder of _that_, apply the respective label lenses,
* sort the list alphanumerically[7].
* Set the sorted list aside.

Before we can consider sorting the values, we need to round up all the
_resource_ objects in the filtered statements[2], obtain their
asserted types, and apply the appropriate label lens[3] to each that
has one.

Resource values that are rendered by sublenses[4] (i.e., inline) will
themselves require some kind of sorting criterion, such as a date (or
ideally multiple criteria in the case of a tie).

It is conceivable that a property can have resource and literal values
mixed in together. It is also conceivable that some of these values
are mixed in by mistake. It is desirable, then, to sort values by
_type_ prior to other sorting criteria, and/or hide values based on
their (data)type.

### Comparing Strings

We consider three different sorting schemes for literals:

* Strictly lexical, i.e., naïvely comparing values of Unicode
  codepoints
* Strictly numeric, i.e., the default for all numeric and datelike XSD
  types (although datelike values should be normalized to the same
  time zone where applicable)
* "Smart" alphanumeric, which splits each value into an array and
  attempts to compare numeric-looking subcomponents numerically before
  comparing them lexically (e.g. like in macOS Finder)

> `rdf:XMLLiteral` values should be put through the equivalent of
> XPath `normalize-space()` before being compared. Also we should
> collate the values to e.g. Unicode NFKC before comparing them.

`rdf:langString` literals, i.e., those with RFC3066/4646/5646 language
identifiers, should be shown/hidden/sorted according to language
preferences (à la `Accept-Language`). Note that a preference for
`en-ca, fr, en` will match a string that is `en-us` (or any other
`en`) only _after_ matching `fr-*`. The system may provide its own
language preference stack if none is supplied by the user. Since we
are only looking at strings (and have no other dimensions with which
to weigh content negotiation), language tags without an explicit `q=`
value will begin at 1 and multiplied successively by 0.999 in the
order they are received. As in HTTP, an explicit `q=0` disqualifies
the specified language from appearing in the results.

## Recurse into sublenses

uh basically do the same thing over and over lol

# Footnotes

1. Selecting a lens is _mostly_ defined in the Fresnel spec, though
   the handling of `owl:equivalentClass`/`rdfs:subClassOf` is only
   hinted at. We propose to "penalize" topological distance so a lens
   with a "closer" `fresnel:classLensDomain` to a resource's asserted
   classes will be selected over a "farther" one. (Although the
   penalty for `owl:equivalentClass` should be considerably smaller
   than `rdfs:subClassOf`.)
2. Reverse statements may hold the subject in a list or collection, in
   which case we will want to traverse the graph until we find another
   addressable resource (e.g. that connects to the head of a list for
   which the subject is a member).
3. I admit I am referencing part of this process before defining
   it, but it can't be helped. In essence, a label lens is one
   that returns at most one literal value (although I suppose it
   could return a sequence according to `fresnel:mergeProperties`).
4. Sublenses are tied to `fresnel:PropertyDescription` objects, so
   _all_ values will be processed with the same sublens.

