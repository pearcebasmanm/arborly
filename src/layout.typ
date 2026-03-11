/// The maximum distance left of center of a node and its children
/// Only works when left-aligned
#let left-chunk((children, body-width)) = {
  if children.len() == 0 {
    body-width / 2
  } else {
    calc.max(body-width / 2, left-chunk(children.first()))
  }
}

#let right-chunk((children, body-width)) = {
  if children.len() == 0 {
    body-width / 2
  } else {
    calc.max(body-width / 2, right-chunk(children.last()))
  }
}

#let calc-child-width(children, horizontal-gap) = {
  let child-width = children.map(node => node.width).sum(default: 0pt)
  if children.len() > 1 {
    child-width += (children.len() - 1) * horizontal-gap
  }
  child-width
}

#let propagate-width((children, body-width, style, ..rest), horizontal-gap) = {
  let children = children.map(node => propagate-width(node, horizontal-gap))
  let child-width = calc-child-width(children, horizontal-gap)
  let width = if style.align == right and children.len() >= 1 {
    let right-chunk = right-chunk((children, body-width))
    let left-chunk = calc.max(body-width / 2, child-width - right-chunk)
    left-chunk + right-chunk
  } else {
    calc.max(body-width, child-width)
  }
  (
    children: children,
    width: width,
    body-width: body-width,
    style: style,
    ..rest,
  )
}

// Propagate a change to the offset of all children
#let propagate-offset((children, offset, ..rest), difference) = {
  let new-children = ()
  for child in children {
    new-children.push(propagate-offset(child, difference))
  }
  children = new-children
  (
    children: children,
    offset: offset + difference,
    ..rest,
  )
}

#let calculate-offset-average((children, width), child-width) = {
  let first-offset = children.first().offset-from-left
  let last-offset = child-width - (children.last().width - children.last().offset-from-left)
  (first-offset + last-offset) / 2
}

// Uses the align: right style, but is still an offset from the left edge to the center
#let calculate-offset-right((children, width, body-width)) = {
  width - right-chunk((children, body-width))
}

#let pair-offset(left, right, horizontal-gap: none) = {
  let left = (left,)
  let right = (right,)

  let max-sep = 0pt
  while left.len() > 0 and right.len() > 0 {
    let sep = (left.last().body-width + right.first().body-width) / 2 + (left.last().offset - right.first().offset)
    if sep.to-absolute() > max-sep.to-absolute() {
      max-sep = sep
    }
    let new-left = ()
    let new-right = ()
    for node in left {
      for child in node.children {
        new-left.push(child)
      }
    }
    for node in right {
      for child in node.children {
        new-right.push(child)
      }
    }
    left = new-left
    right = new-right
  }
  max-sep + horizontal-gap
}

#let apply-tight-fit(children, style, horizontal-gap) = {
  let seps = ()
  for (left, right) in children.windows(2) {
    seps.push(pair-offset(left, right, horizontal-gap: horizontal-gap))
  }

  // NOTE: this is probably the heaviest section of code, being at least 4 layers of looping.
  for n in range(3, children.len() + 1) {
    for (i, window) in children.windows(n).enumerate() {
      let current-sep = seps.slice(i, i + n - 1).sum()
      let calculated-sep = pair-offset(window.first(), window.last())
      if current-sep.to-absolute() < calculated-sep.to-absolute() {
        let amortized-difference = (calculated-sep - current-sep) / (n - 1)
        for j in range(i, i + n - 1) {
          seps.at(j) += amortized-difference
        }
      }
    }
  }

  let sep-sum = seps.sum(default: 0pt)

  let difference = if align == left {
    0pt
  } else if align == right {
    -sep-sum
  } else {
    -sep-sum / 2
  }

  let new-children = ()
  for i in range(children.len()) {
    new-children.push(propagate-offset(children.at(i), difference))
    if i < seps.len() {
      difference += seps.at(i)
    }
  }

  new-children
}

#let apply-band-fit(children, align, horizontal-gap, body-width) = {
  let child-width = calc-child-width(children, horizontal-gap)
  let width = if align == right and children.len() >= 1 {
    let right-chunk = right-chunk((children, body-width))
    let left-chunk = calc.max(body-width / 2, child-width - right-chunk)
    left-chunk + right-chunk
  } else {
    calc.max(body-width.to-absolute(), child-width.to-absolute())
  }

  if children.len() == 0 {
    return (children, width, body-width / 2)
  }

  let offset-from-left = if align == center {
    // |-------|
    //       ==o==
    //    =o=    ==o==
    // ====o====
    calculate-offset-average((children: children, width: width), child-width)
  } else if align == left {
    // |---|
    //   ==o==
    //    =o=    ==o==
    // ====o====
    left-chunk((children: children, body-width: body-width))
  } else if align == right {
    // |-----------|
    //           ==o==
    //    =o=    ==o==
    // ====o====
    calculate-offset-right((children: children, width: width, body-width: body-width))
  } else {
    panic("alignment not implemented: " + align)
  }

  let difference = if align == center {
    -offset-from-left
  } else if align == left {
    -calc.min(offset-from-left, left-chunk(children.first()))
  } else if align == right {
    -calc.min(offset-from-left, child-width - right-chunk(children.last()))
  } else {
    panic("alignment not implemented: " + align)
  }

  let new-children = ()
  for child in children {
    new-children.push(propagate-offset(child, difference + child.offset-from-left))
    difference += child.width + horizontal-gap
  }

  (new-children, width, offset-from-left)
}

#let compute-horizontal-offset(
  (children, ..rest),
  horizontal-gap,
) = {
  // run recursively
  let new-children = ()
  for child in children {
    new-children.push(compute-horizontal-offset(child, horizontal-gap))
  }
  children = new-children

  let style = rest.style
  let body-width = rest.body-width

  // apply the relevant fitting algorithm
  if style.fit == "tight" {
    let children = apply-tight-fit(children, style.align, horizontal-gap)

    (
      children: children,
      // Unused in this branch but might be used elsewhere,
      // in which case this is the wrong behavior but 🤷
      width: 0pt,
      offset-from-left: 0pt,
      ..rest,
    )
  } else if style.fit == "band" {
    let (children, width, offset-from-left) = apply-band-fit(children, style.align, horizontal-gap, body-width)

    (
      children: children,
      width: width,
      offset-from-left: offset-from-left,
      ..rest,
    )
  } else {
    panic("fit not implemented: " + style.fit)
  }
}

