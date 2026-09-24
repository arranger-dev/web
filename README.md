# arranger-web

The landing page for [arranger](https://github.com/arranger-dev/arranger). A single static page: no build step, no dependencies.

```text
index.html     the page
fonts.css      IBM Plex Sans / Plex Serif and Lilex (SIL OFL 1.1), the same type as the app
fonts/         the font files
arranger.png   logo and favicon
```

Preview it locally:

```sh
python3 -m http.server 8080   # then open http://localhost:8080
```

Deploy it by publishing this folder as is (GitHub Pages, Netlify, Cloudflare Pages, any static host). All asset paths are relative, so it also works from a subpath.
