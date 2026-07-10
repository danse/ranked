# ranked

A CLI tool that parses a file of `URL,counter` pairs, picks one with
probability related to its rank, serialises the cycled list back, and
opens the selected URL in your browser.

The easiest way to start is with a file of URLs only (no counters yet).
The tool treats lines without a comma as having counter 0.

## Usage

```
ranked [-o] [-u | -d] FILE
```

- `FILE` — each line contains a URL and an integer counter separated by
  a comma (e.g. `example.com,42`). The last comma on the line
  separates the URL from the counter. Lines without a comma default to
  counter 0.
- `-o` — write to stdout instead of editing the file in place (default)
- `-u` — increment rank for last visited location (now at the bottom)
- `-d` — decrement rank as above (negative ranks allowed)

### Example

```sh
$ cat > /tmp/links.txt <<EOF
xkcd.com
news.ycombinator.com
github.com
EOF

$ ranked -o /tmp/links.txt
news.ycombinator.com,0
github.com,0
xkcd.com,0
```

## Build & test

```sh
cabal build
cabal test
bash manual/cli.sh
bash manual/coverage.sh    # coverage report + HTML
```