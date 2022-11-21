# fgg - free gallery generator

fgg is a free gallery generator for static site generators like Hugo, Jekyll, Nikola etc. using Flickr as data source.

## Introduction

More to come...

## Requirenents:

- Python 3.* (I don't now the concrete version right now. I use only Python 3.10 at the moment. Could be that fgg is 
  running with an older version, but it could also be that required libs do not. Please report your Python version to 
  me if fgg works for you to help me to create a compatibility list.)
- crc32c 2.3 - [https://pypi.org/project/crc32c/](https://pypi.org/project/crc32c/)
- flickr-api 0.7.5 - [https://pypi.org/project/flickr-api/](https://pypi.org/project/flickr-api/)
- requests 2.28.1 - [https://pypi.org/project/requests/](https://pypi.org/project/requests/)

## To do:

- Make it possible to recreate the gallery even when there are no photos at Flickr anymore!!!
- Error handling. Not done in any way so far... :|
- Make use of some CLI parameters to make it more comfortable to use fgg.
- Configure the Python logging stuff and add logging for easy debugging... ;)
- ~~Save as most cached data as JSON files as possible. Object dumps are related to Ruby only at the moment.
  So limit the use of Marshal to a minimum!~~ No marshal nor pickle is used anymore. All cache is JSON.
- ~~Rewrite fgg in Python. **Ruby is a weird language o_O!**~~ Python is the now the language of choice.
- Use a template engine for HTML output generation, but not before the rewrite in Python.
- Add more targets, not only Jekyll. Nikola preferred!
- Maybe add more photo sources, not only Flickr.
- ~~Define what is definitely needed in metadata to generate a gallery even when offline.~~ Should be done but maybe 
needs more enhancements.
- Add API call to delete a photo in the source after downloading and creating metadata file.
- Tons of stuff... :)
