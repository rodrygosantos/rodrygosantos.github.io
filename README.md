# Rodrygo Santos's website

This repository contains the Quarto source for <https://rodrygosantos.github.io/>.

## Build locally

Install [Quarto](https://quarto.org/) and render the complete site from the repository root:

```sh
quarto render
```

The generated static site is written to `_site/`.

## Publish to GitHub Pages

Pushing changes to `master` runs the `Quarto Publish` GitHub Actions workflow. It renders the site with the latest stable Quarto release and publishes the result to the `gh-pages` branch, which serves <https://rodrygosantos.github.io/>.

## Publish to the DCC home page

After rendering, upload the contents of `_site/` to `/home/prof/rodrygo/public_html` on `mica.dcc.ufmg.br` using key-based SSH. This updates <https://homepages.dcc.ufmg.br/~rodrygo/>.
