/// Returns a subslice of an list of content with any "empty" elements stripped from the start and end
#let trim(list) = {
  let empty-elements = (parbreak(), [ ])
  // trim start
  while list.len() >= 1 and list.at(0) in empty-elements {
    list = list.slice(1)
  }
  // trim end
  while list.len() >= 1 and list.at(list.len() - 1) in empty-elements {
    list = list.slice(0, list.len() - 1)
  }
  list
}

// nodes are delimited by [ and ]
// this is shorthand for checking if content is one of those
// Typst parses paired brackets [] differently from an escaped one \[ which is why I use the former
#let is-opening(content) = content == [[]].children.at(0)
#let is-closing(content) = content == [[]].children.at(1)
/// Check whether the content is my tagged arborly node metadata
#let is-metadata(content) = (
  content.func() == metadata
    and type(content.value) == array
    and content.value.len() == 2
    and content.value.at(0) == "arborly-metadata"
)

/// Parses a list like (A, [, B, ], [, C, ]) into a tree like
/// (
///   body: [A],
///   children: (
///     (body: [B], children: (), style: (:),
///     (body: [C], children: (), style: (:),
///   ),
///   style: (:),
/// )
#let parse-recursive(list) = {
  list = trim(list)

  // ie. for "A[B]" this will be index 1, the index of [
  let child-opener = list.position(is-opening)

  // parse the children (either 0 or 1+ of them)
  let (body-slice, children) = if child-opener == none {
    (list, ())
  } else {
    let body-slice = trim(list.slice(0, child-opener))
    let children-slice = trim(list.slice(child-opener))
    let children = ()
    while children-slice.len() > 0 {
      let child-closer = 0
      let level = 1
      while level > 0 {
        child-closer += 1
        if is-opening(children-slice.at(child-closer)) {
          level += 1
        }
        if is-closing(children-slice.at(child-closer)) {
          level -= 1
        }
      }
      children.push(parse-recursive(children-slice.slice(1, child-closer)))

      children-slice = trim(children-slice.slice(child-closer + 1))
    }

    (body-slice, children)
  }

  // Extract attributes
  let style-metadata = body-slice.find(is-metadata)
  let style = if style-metadata != none {
    style-metadata.value.at(1)
  } else {
    (:)
  }

  (body: body-slice.sum(default: none), children: children, style: style)
}

// parse-recursive operates on a list, we we need to turn our content into a list first
// this relies on the fact that paired brackets "[]" are always their own child and don't create futher nesting, so
// `#[A[B][C]].children == ([A], [[], [B], []], [C], []])`
#let parse(body) = {
  parse-recursive(body.at("children", default: (body,)))
}
