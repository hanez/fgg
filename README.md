# fgg - free gallery generator

fgg is a free gallery generator for static site generators like Hugo, Jekyll, Nikola etc. using Flickr as data source.

## Introduction

More to come...

## To do:

- Error handling. Not done in any way so far... :|
- ~~Save as most cached data as JSON files as possible. Object dumps are related to Ruby only at the moment.
  So limit the use of Marshal to a minimum!~~ Nor marshal nor pickle is used anymore. All cache is JSON.
- ~~Rewrite fgg in Python. **Ruby is a weird language o_O!**~~ Python is the now the language of choice.
- Use a template engine for HTML output generation, but not before the rewrite in Python.
- Add more targets, not only Jekyll. Nikola preferred!
- Maybe add more photo sources, not only Flickr.
- ~~Define what is definitely needed in metadata to generate a gallery even when offline.~~ Should be done but maybe 
needs more enhancements.
- Add API call to delete a photo in the source after downloading and creating metadata file.
- Tons of stuff... :)
