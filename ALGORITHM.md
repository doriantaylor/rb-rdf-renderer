# The Algorithm

The main objective of our Fresnel processor is to produce
(X)HTML+RDFa. Notwithstanding, Fresnel was invented several years
before RDFa. We will therefore need to make several adjustments to the
algorithm to make sure the graph structure stays preserved when
embedded in an (X)HTML document.

## Given the subject, select a lens[1].

The lens selection process is [detailed in the Fresnel
spec](https://www.w3.org/2005/04/fresnel-info/manual/#lensspecific).
First we attempt to match an _instance_ (exact URI), and if that is
not successful, we move on to the _class_ (`rdf:type`) of the subject.
`fresnel:classLensDomain` declarations are intended to match resource
classes _and_ superclasses (through `rdfs:subClassOf`). The Fresnel
spec is silent, however, about `owl:equivalentClass`, which we view to
also be eligible for traversing in order to match classes to lenses.

Since matching classes is the most likely method of selecting a lens
to render a given subject, we will give this scenario significant
consideration. Exact matches between asserted classes and lens domains
should always get top priority. Beyond there, we start to discount: a
lesser penalty for `owl:equivalentClass` and a stiffer one for
`rdfs:subClassOf`. This will ensure that more topologically "distant"
matches are less likely to supersede over "closer" ones. It is also
possible that a subject will have more than one class asserted for
which there is more than one equally-scored matching lens. In the
event of a perfect tie, we can disambiguate with `<#lens>
fresnel:purpose fresnel:defaultLens` or `<#lens> flx:priority 31337`.

> I am not entirely sure what to do yet about _inferred_ classes,
> except to say that they should only be considered _after_ any
> asserted classes, and _only_ after subtracting any classes that are
> not in the resolution path (`owl:equivalentClass`,
> `rdfs:subClassOf`) of any asserted classes.

The propensity for new vocabularies to be added to the graph is very
low, and likewise lenses will be added and modified very
infrequently. As such it would make sense to compute the
equivalent/*sub*classes on the _lenses_ at compile time rather than
equivalents/*super*classes on the _subjects_ at _render_ time.

> There will be the inevitable cache invalidation problem to the
> extent that any persistent system will need hooks to refresh the
> lenses if they are modified, but it will probably need hooks for
> other things anyway.

> Actually what we want is a compromise: a lens for a sufficiently
> basic class (`owl:Thing` or `rdfs:Resource`) is going to scan the
> entire (hopefully) DAG of subclasses which will take forever to
> scan, so we _do_ want to go _up_ the tree. In this case we could
> create a mapping of the form `{ typeof => { lens => score } }` to
> get a shortlist of lenses. We could make that shortlist even shorter 

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

## Use Cases

> move this out into its own document maybe

### Show metadata about a document

### Show a record of a person with their employment history

> (in reverse chronological order)

Okay so first issue we encounter is the person's name. Let's suppose
the default label is `foaf:name` but we can't rely on that to be
present so we concatenate `foaf:givenName` to `foaf:surname` via
`fresnel:mergeProperties`:

```turtle
<#personLabelLens> a fresnel:Lens ;
    fresnel:purpose fresnel:labelLens ;
    fresnel:showProperties [ a fresnel:PropertyDescription ;
        fresnel:mergeProperties (foaf:givenName foaf:surname) ] .
```

But what we actually _need_ is something more like this:

```turtle
<#personLabelLens> a fresnel:Lens ;
    fresnel:purpose fresnel:labelLens ;
    fresnel:showProperties [ a fresnel:PropertyDescription ;
        fresnel:alternateProperties (foaf:name
            [ a fresnel:PropertyDescription ;
                fresnel:mergeProperties (foaf:givenName foaf:familyName) ]
            ) ] .
```

Although _really_, since we're dealing with FOAF, and nobody has gone
and updated the morass of naming properties, what we probably
_actually_ want is something like this:

```turtle
<#personLabelLens> a fresnel:Lens ;
    fresnel:purpose fresnel:labelLens ;
    fresnel:showProperties [ a fresnel:PropertyDescription ;
        fresnel:alternateProperties (foaf:name
            [ a fresnel:PropertyDescription ;
                fresnel:mergeProperties (
                    [ a fresnel:PropertyDescription ;
                        fresnel:alternateProperties (
                            foaf:firstName foaf:givenName foaf:givenname) ]
                    [ a fresnel:PropertyDescription ;
                        fresnel:alternateProperties (foaf:familyName
                            foaf:lastName foaf:surname foaf:family_name) ] ) ]
            ) ] .
```

> This kind of situation is emblematic of trying to render data we do
> not control, e.g. dbPedia. This structure is what we would need to
> express all the potential permutations of first-last names _and not
> even_ accounting for the fact that e.g. Chinese or Hungarian names
> go last-first, although it is conceivable some downstream processor
> could handle this situation.

> Note as well that the property descriptions, the topmost one in
> particular, could be given a URI and made reusable.

```turtle
<#nameDesc> a fresnel:PropertyDescription ;
    fresnel:alternateProperties (foaf:name
        [ a fresnel:PropertyDescription ;
            fresnel:mergeProperties (
                [ a fresnel:PropertyDescription ;
                    fresnel:alternateProperties (
                        foaf:firstName foaf:givenName foaf:givenname) ]
                [ a fresnel:PropertyDescription ;
                    fresnel:alternateProperties (foaf:familyName
                        foaf:lastName foaf:surname foaf:family_name) ] ) ] ) .

<#personLabelLens> a fresnel:Lens ;
    fresnel:purpose fresnel:labelLens ;
    fresnel:showProperties <#nameDesc> .
```

We can model the person's employment history through
`org:hasMembership`, which has a range of `org:Membership`, which
itself has a `org:memberDuring` property, which takes a
`time:Interval`, which itself has a `time:hasBeginning` and
`time:hasEnd`, which point to `time:Instant`s, which specifies a
`time:inXSDDateTime`, which is supposed to be an `xsd:dateTime`, which
we can compare.

A SPARQL property path for such an object would be
`org:memberDuring/time:hasBeginning/time:inXSDDateTime`, but Fresnel
predates SPARQL 1.1 by several years. They have [their own selector
language](https://www.w3.org/2005/04/fresnel-info/fsl/) that looks
a lot like XPath:
`org:memberDuring/*/time:hasBeginning/*/time:inXSDDateTime`. (FSL has
to specify nodes—in this case, wildcards—as well as edges.)

> Note that SHACL has features that can describe what both SPARQL and
> FSL property paths attempt, and it does it in RDF which can be
> manipulated directly rather than some other syntax.

There is still the issue of specifying a sorting criterion, which is
missing from Fresnel. Here we propose `flx:sortValuesBy` which can
take as its range `rdf:Property`, `flx:SortPropertyList`, or
`flx:SortingPolicy`.

```turtle
<#membershipDesc> a fresnel:PropertyDescription ;
    fresnel:property org:hasMembership ;
    flx:sortValuesBy (
        [ a flx:SortingPolicy ;
            sh:path (org:memberDuring time:hasEnd time:inXSDDateTime) ;
            # ignore everything that isn't a dateTime
            sh:datatype xsd:dateTime ;
            # we want this reverse chronological
            flx:descending true ]
        # if there is no end date, then we sort from the beginning
        [ a flx:SortingPolicy ;
            sh:path (org:memberDuring time:hasBeginning time:inXSDDateTime) ;
            sh:datatype xsd:dateTime ;
            flx:descending true ]
        # otherwise, we sort by whatever label lens is returned 
        [ a flx:SortingPolicy ;
            sh:path org:organization ] ) .

<#resumeLens> a fresnel:Lens ;
    fresnel:showProperties (
        foaf:name
        # some other properties ...
        <#membershipDesc> ) .
```


## Footnotes

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

