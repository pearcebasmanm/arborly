# Syntree

A library for producing syntax tree graphs.

## Examples

## Usage

This package requires typst 0.13

To use this package, simply add the following code to your document:

```typ
#import "@preview/syntree:0.1.0"

#let tree = ("TP", (
  ("NP", (
    ("N", "this"),
  )),
  ("VP", (
    ("V", "is"),
    ("NP", (
      ("D", "a"),
      ("N", "wug"),
    )),
  )),
))

#syntree.tree(min-slope: 0.2, label-alignment: "smart", tree)
```
