# fgg - free gallery generator

fgg is a free gallery generator for static site generators like Hugo, Jekyll, Nikola etc. using Flickr as data source.

## Introduction

More to come...

## To do:

- Save as most cached data as JSON files as possible. Object dumps are related to Ruby only at the moment.
  So limit the use of Marshal to a minimum!
- Rewrite fgg in Python. **Ruby is a weird language o_O!**
- Use a template engine for HTML output generation, but not before the rewrite in Python.
- Add more photo sources, not only Flickr.
- Add more targets, not only Jekyll. Nikola preferred!
- Define what is definitely need in metadata to generate a gallery even when offline.
- Add API call to delete a photo in the source after downloading and creating metadata file.
- Tons of stuff...
