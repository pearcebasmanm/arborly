#import "@preview/cetz:0.4.2"

// This uses a non-recursive approach to get around the depth limit
// for very deep trees, but as a consequence is harder to read.
#let draw(
  node,
  y: 0,
  name: "0",
  vertical-snapping-threshold: none,
  vertical-gap: none,
) = {
  let call-stack = ((node: node, y: y, name: name),)
  // Line elements are collected here and shown at the end, because they rely on element names that do not exist until later iterations of the call loop.
  let lines = ()

  while call-stack.len() > 0 {
    let (node: node, y: y, name: name) = call-stack.pop()
    let (
      body,
      children,
      offset,
      style,
      offset-from-left,
      body-height,
    ) = node

    // START OF ACTUAL IMPLEMENTATION
    let name = if style.name != none { style.name } else { name }
    cetz.draw.content(
      (offset.to-absolute().cm(), y),
      body,
      padding: style.padding,
      name: name,
    )

    for i in range(children.len()) {
      let child = children.at(i)

      // Calculate the offset
      let DEFAULT_HEIGHT = measure([dj]).height
      let average-height = (body-height + child.body-height) / 2
      let snapped-height = if calc.abs(DEFAULT_HEIGHT - average-height) <= vertical-snapping-threshold.to-absolute() {
        DEFAULT_HEIGHT
      } else {
        average-height
      }

      let line-style = cetz.util.merge-dictionary(style.child-lines, child.style.parent-line)

      let child-y = y - snapped-height.cm() - vertical-gap.to-absolute().cm()
      // let child-y = y - snapped-height.cm()
      let child-name = if child.style.name != none { child.style.name } else { name + "-" + str(i) }

      call-stack.push((
        node: child,
        y: child-y,
        name: child-name,
      ))
      if child.style.triangle {
        lines.push(
          cetz.draw.line(
            (name: name, anchor: "south"),
            (name: child-name, anchor: "north-west"),
            (name: child-name, anchor: "north-east"),
            close: true,
            ..line-style,
          ),
        )
      } else {
        lines.push(
          cetz.draw.line(
            if style.child-anchor != none {
              (name: name, anchor: style.child-anchor)
            } else {
              name
            },
            if child.style.parent-anchor != none {
              (name: child-name, anchor: child.style.parent-anchor)
            } else {
              child-name
            },
            ..line-style,
          ),
        )
      }
    }
    // END OF ACTUAL IMPLEMENTATION
  }

  lines.join()
}

