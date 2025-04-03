# svgtocairo

This library aims to be a minimal and reasonably-performant method of loading
SVG files as surfaces for use with [Nim's Cairo binding](https://github.com/nim-lang/cairo).

This exists because wrapping [librsvg](https://github.com/GNOME/librsvg/) felt more
hacky than just building the functionality directly with pure Nim, and the SVG-loading
functionality may need to be customized from what librsvg offers in the future, for
my primary use case.

Documentation will be handled once the project reaches a stable and fairly complete
state. Though, it's a pretty simple API, so reading the source is adequate. The gist
of it is:

``` nim
import svgtocairo
discard svgToSurface("myfile.svg")
```
