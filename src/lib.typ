/// Used for adding attributes to nodes. See the Styling and Attributes section for more details.
#let a(..args) = metadata(("arborly-metadata", args.named()))

/// Generate a syntax tree
///
/// -> content
#let tree(
  /// A root style dictionary that is inherited by all nodes. Any more specific configuration within the tree takes precedence.
  ///
  /// -> dictionary
  style: (:),
  /// If the height of a node's content differs from regular text by less than this amount, it will be vertically spaced as though it had the same height.
  ///
  /// This is not useful if most nodes are significantly larger than simple text (eg. being surrounded by `rect`).
  ///
  /// -> length
  vertical-snapping-threshold: 0.5em,
  /// The vertical gap between nodes
  ///
  /// -> length
  vertical-gap: 2em,
  /// The horizontal gap between nodes
  ///
  /// -> length
  horizontal-gap: 1.75em,
  /// A code block to be inserted into the cetz canvas after the syntax tree. It can be used for drawing arrows between nodes. Remember to name nodes using ```typ #a``` in order to reference them. See Styling and Arguments for more.
  ///
  code: none,
  /// The tree's structure denoted using bracket-enclosed values, as described in Building a Syntax Tree
  ///
  /// -> content
  body,
) = context {
  // Library Imports
  import "@preview/cetz:0.4.2": canvas

  // Local Imports
  import "parse.typ": parse
  import "style.typ": propagate-style
  import "layout.typ": compute-horizontal-offset
  import "draw.typ": draw

  let node = parse(body)
  let node = propagate-style(node, style)
  let node = compute-horizontal-offset(node, horizontal-gap)

  canvas({
    draw(
      node,
      vertical-snapping-threshold: vertical-snapping-threshold,
      vertical-gap: vertical-gap,
    )
    code
  })
}
