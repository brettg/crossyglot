# Crossyglot

Ruby library for parsing and writing common crossword file formats. `.puz` and
`.jpz` files are currently supported.

## Requirements 

* Ruby >= 2.1

## Examples

Parsing:

```
  puzzle = Crossyglot::Puzzle.parse_file('fun.puz')
  # Example available attributes:
  puzzle.title
  puzzle.acrosses
  puzzle.word_count
```

Convert to a different format and write to file:

```
  puzzle = Crossyglot::Puzzle.parse_file('fun.puz')
  puzzle.convert_to(:jpz).write('fun.jpz')

```

