#import "@preview/cetz:0.4.2": util.merge-dictionary

#let DEFAULT_STYLE = (
  align: center,
  align-content: center,
  triangle: false,
  parent-line: (:),
  child-lines: (:),
  parent-anchor: "north",
  child-anchor: "south",
  text: (:),
  padding: 0.5em,
  name: none,
  fit: "tight",
)

/// Fills out all styling options for all nodes with the following priority:
///
/// 1. The styling specified for that node
/// 2. The styling inherited from the parent
/// 3. The styling passed into ```typc tree```
/// 4. The default styles
#let propagate-style((body, children, style), parent-style) = {
  // update the parent-style for all children with inherited values
  if "inherit" in style.keys() {
    parent-style = merge-dictionary(parent-style, style.inherit)
    style.remove("inherit")
  }

  // apply function recursively on children
  let new-children = ()
  for child in children {
    new-children.push(propagate-style(child, parent-style))
  }
  children = new-children

  let fallback-style = merge-dictionary(DEFAULT_STYLE, parent-style)

  style = merge-dictionary(fallback-style, style)

  let body = {
    set text(bottom-edge: "baseline")
    set text(..style.text)
    align(style.align-content, body)
  }

  (
    body: body,
    children: children,
    style: style,
    // TODO: move this to separate pass for separation of concerns
    // Measurements cannot be taken before this point since styling can affect them
    body-height: measure(body).height,
    body-width: measure(body).width,
    offset: 0pt, // horizontal offset relative to the root. Gets updated but needs default.
  )
}

