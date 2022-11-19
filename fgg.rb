#!/bin/env ruby

# Copyright (c) 2022 Johannes Findeisen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# fgg - A gallery generator for static site generators using Flickr as data source.
#
# THIS IS THE PROTOTYPE FOR THE PYTHON VERSION OF THIS SCRIPT! IT EXISTS BECAUSE I AM
# USING JEKYLL SINCE SOME YEARS FOR SITE GENERATION. SINCE I AM SWITCHING TO NIKOLA
# WHICH IS WRITTEN IN PYTHON THIS WILL BECOME OBSOLETE ASAP SINCE MY FAVORITE LANGUAGE
# IS PYTHON AND RUBY REALLY SUCKS IN MANY WAYS...
#
# This is a port from a prototype I have running since some years. I want to port
# this to Python in the future.
#
# Flickr API documentation
# https://www.flickr.com/services/api/

require 'date'
require 'digest'
require 'digest/crc32'
require 'fileutils'
require 'flickraw'
require 'json'
require 'openssl'

FlickRaw.api_key = ENV["FLICKR_API_KEY"]
FlickRaw.shared_secret = ENV["FLICKR_SHARED_SECRET"]
flickr.access_token = ENV["FLICKR_ACCESS_TOKEN"]
flickr.access_secret = ENV["FLICKR_ACCESS_SECRET"]

# error = 0
# warning = 1
# info = 2
# debug = 3
def barf(message, log)
    if log == 0
        puts("ERROR: " + message)
    end
    if log == 1
        puts("WARNING: " + message)
    end
    if log == 2
        puts("INFO: " + message)
    end
    if log == 3
        puts("DEBUG: " + message)
    end
end

def fill_zeros(number, digit_count=3)
    format_string = "%0#{digit_count}d"
    return format_string % (number % 10**digit_count)
end

def get_count(flickr, photos_per_page, page)
    # https://www.flickr.com/services/api/flickr.photos.getWithoutGeoData.html
    count = flickr.photos.getWithoutGeoData(:sort => 'date-taken-desc', :per_page => photos_per_page, :page => page).length
end

barf("Logging in to Flickr...", 2)
login = flickr.test.login
barf("You are now authenticated as #{login.username}", 2)

# the timezone difference to UTC
tz_diff = "+01:00"

page = 1
page_count = 0
photo_count = 0
photos_per_page = 500
barf("Counting Pages...", 2)
while get_count(flickr, photos_per_page, page) != 0 do
    count = get_count(flickr, photos_per_page, page)
    photo_count = photo_count + count
        print "."
        STDOUT.flush
    page = page + 1
    page_count = page_count + 1
end
barf("", 2)

barf("Page Count: " + page_count.to_s(), 2)
barf("Photo Count: " + photo_count.to_s(), 2)

overall_tags = []
page = 1
photo = photo_count
photo_map = {}
while page <= page_count do
    barf("Page: " + page.to_s, 2)

    # https://www.flickr.com/services/api/flickr.photos.getWithoutGeoData.html
    photo_list = flickr.photos.getWithoutGeoData(:sort => 'date-taken-desc', :per_page => photos_per_page, :page => page)
    photo_list.each_with_index do
        |flickr_photo|
        barf("Photo: " + photo.to_s, 2)

        ##puts(flickr_photo.inspect)
        ##exit

        if File.file?("cache/flickraw/" + flickr_photo.id + "/meta")
            flickr_photo_info = Marshal.load(File.binread("cache/flickraw/" + flickr_photo.id + "/meta"))
        else
            # https://www.flickr.com/services/api/flickr.photos.getInfo.html
            flickr_photo_info = flickr.photos.getInfo(:photo_id => flickr_photo.id)
            FileUtils.mkdir_p("cache/flickraw/" + flickr_photo.id)
            File.open("cache/flickraw/" + flickr_photo.id + "/meta", 'wb') {|f| f.write(Marshal.dump(flickr_photo_info))}
        end
        #flickr_photo_info = flickr.photos.getInfo(:photo_id => flickr_photo.id)
        #puts(flickr_photo_info.inspect)
        #exit

        photo_timestamp = DateTime.parse(flickr_photo_info.dates.taken.to_s + tz_diff).to_time.to_i

        photo_suffix = fill_zeros(photo, 7)
        photo_cache_dir = "cache/photos/" + photo_timestamp.to_s + "-" + photo_suffix
        if Dir.exists?(photo_cache_dir)
            barf("File exists: " + photo_cache_dir, 1)
        else
            FileUtils.mkdir_p(photo_cache_dir)
        end

        barf("Processing photo number: " + photo.to_s, 2)

        barf("Flickr photo id: " + flickr_photo.id, 2)
        photo_map = photo_map.merge!("photo_flickr_id" => flickr_photo.id)

        barf("Flickr photo owner: " + flickr_photo.owner, 2)
        photo_map = photo_map.merge!("photo_flickr_owner" => flickr_photo.owner)

        barf("Flickr photo title: " + flickr_photo.title, 2)
        photo_map = photo_map.merge!("photo_flickr_title" => flickr_photo.title)

        ##barf("Flickr photo description: " + flickr_photo_info.description.partition("[").first, 2)
        ##photo_map = photo_map.merge!("photo_flickr_description" => flickr_photo_info.description.partition("[").first)
        barf("Flickr photo description: " + flickr_photo_info.description, 2)
        photo_map = photo_map.merge!("photo_flickr_description" => flickr_photo_info.description)

        barf("Flickr photo location: " + flickr_photo_info.owner["location"], 2)
        photo_map = photo_map.merge!("photo_flickr_location" => flickr_photo_info.owner["location"])

        barf("Flickr photo username: " + flickr_photo_info.owner["username"], 2)
        photo_map = photo_map.merge!("photo_flickr_username" => flickr_photo_info.owner["username"])

        barf("Date taken: " + flickr_photo_info.dates.taken.to_s, 2)
        photo_map = photo_map.merge!("photo_flickr_date_taken" => "" + flickr_photo_info.dates.taken.to_s + "")

        barf("Date taken timestamp: " + photo_timestamp.to_s, 2)
        photo_map = photo_map.merge!("photo_flickr_date_taken_timestamp" => photo_timestamp)

        barf("Date uploaded: " + flickr_photo_info.dateuploaded.to_s, 2)
        photo_map = photo_map.merge!("photo_flickr_date_uploaded_timestamp" => flickr_photo_info.dateuploaded.to_i)

        ##puts flickr_photo_info.dates.inspect
        ##puts flickr_photo_info.inspect

        # START ########################################################################################################
        # NEVER CHANGE THE FOLLOWING LINES (UNTIL "# END") EXPECT YOU REALLY NEED OR WANT TO CHANGE THE PHOTO ID!!!
        # ALL LINKS TO THIS PHOTO WILL BECOME BROKEN!!! - hanez
        # https://docs.ruby-lang.org/en/master/OpenSSL/Digest.html
        digest1 = OpenSSL::Digest.new("sha256", flickr_photo.id.to_s + flickr_photo_info.dates.taken.to_s)
        digest2 = OpenSSL::Digest.new("sha512", flickr_photo.id.to_s + flickr_photo_info.dates.taken.to_s)
        digest3 = OpenSSL::Digest.new("sha3-256", flickr_photo.id.to_s + flickr_photo_info.dates.taken.to_s)
        digest4 = OpenSSL::Digest.new("sha3-512", flickr_photo.id.to_s + flickr_photo_info.dates.taken.to_s)
        photo_id = Digest::CRC32c.hexdigest(digest1.to_s + digest2.to_s + digest3.to_s + digest4.to_s)
        barf("Photo id: " + photo_id, 2)
        photo_map = photo_map.merge!("photo_id" => photo_id)
        # END ##########################################################################################################

        FileUtils.mkdir_p "photo/" + photo_id

        ## https://westonganger.com/posts/get-substring-between-two-strings-or-characters-in-ruby
        ## get string between last "[" and last "]":
        ##tags = flickr_photo_info.description[/.*\[(.*)\]/, 1]
        ##if tags
        ##    barf("Flickr photo tags: " + tags, 2)
        ##    photo_map = photo_map.merge! "photo_flickr_tags" => tags
        ##else
        ##    barf("Flickr photo tags: " + "", 2)
        ##    photo_map = photo_map.merge! "photo_flickr_tags" => ""
        ##end
        ##puts(flickr_photo_info.tags.inspect)
        if File.file?(photo_cache_dir + "/tags.array")
            tags = Marshal.load(File.binread(photo_cache_dir + "/tags.array"))
        else
            tags = []
            flickr_photo_info.tags.each_with_index do
                |flickr_photo_tags|
                tags.push(flickr_photo_tags.raw.downcase)
            end
            File.open(photo_cache_dir + "/tags.array", 'wb') {|f| f.write(Marshal.dump(tags))}
        end
        overall_tags = overall_tags | tags
        photo_map = photo_map.merge!("photo_flickr_tags" => tags)

        # convert 2004-11-19 12:51:19 to 20041119125119
        photo_date = flickr_photo_info.dates.taken
        photo_date = photo_date.to_s()
        photo_date["-"] = ""
        photo_date["-"] = ""
        photo_date[" "] = ""
        photo_date[":"] = ""
        photo_date[":"] = ""
        barf("Photo date: " + photo_date, 2)
        photo_map = photo_map.merge!("photo_date" => photo_date)

        photo_map = photo_map.merge!("photo_timezone" => "UTC" + tz_diff)

        # the filename should be optimized to create a more beautiful filename
        filename = String.new(flickr_photo_info.title.tr("\s", "-"))
        filename = filename.delete("\'\"\.\s\,\!\/\:\(\)\[\]\;\?\&\<\>\$\%")
        filename = filename.gsub("--", "-")

        barf("Filename: " + filename, 2)
        photo_map = photo_map.merge!("photo_filename" => filename)

        if File.file?("cache/flickraw/" + flickr_photo.id + "/sizes")
            sizes = Marshal.load(File.binread("cache/flickraw/" + flickr_photo.id + "/sizes"))
        else
            # https://www.flickr.com/services/api/flickr.photos.getSizes.html
            sizes = flickr.photos.getSizes(:photo_id => flickr_photo.id)
            File.open("cache/flickraw/" + flickr_photo.id + "/sizes", 'wb') {|f| f.write(Marshal.dump(sizes))}
        end

        #puts(sizes.inspect)
        #exit

        photo_sizes_map = {}
        sizes.each_with_index do
            |flickr_photo_sizes|

            photo_size_map = {}
            size = flickr_photo_sizes.url[-2, 1]
            if flickr_photo_sizes.label == "Square"
                size = "x"
            end
            barf("Photo size: " + size, 3)
            photo_size_map = photo_size_map.merge!("size" => size)

            photo_target_size = flickr_photo_sizes.label.tr(" ", "-")
            photo_target_file = "photo/" + photo_id + "/" + filename + "-" + photo_date + "-" + photo_suffix + "-" + photo_target_size + ".jpg"
            if !File.file?(photo_target_file)
                cmd = "wget -U Foo -O " + photo_target_file + " " + flickr_photo_sizes.source
                exec = `#{cmd}`
            end

            barf("Photo target: " + photo_target_file, 3)
            photo_size_map = photo_size_map.merge!("target_file" => photo_target_file)

            photo_digest = Digest::SHA1.file(photo_target_file)
            photo_digest = photo_digest.hexdigest
            photo_digest = photo_digest.to_s()
            barf("Photo digest (SHA1): " + photo_digest, 3)
            photo_size_map = photo_size_map.merge!("digest_sha1" => photo_digest)

            photo_digest = Digest::SHA256.file(photo_target_file)
            photo_digest = photo_digest.hexdigest
            photo_digest = photo_digest.to_s()
            barf("Photo digest (SHA256): " + photo_digest, 3)
            photo_size_map = photo_size_map.merge!("digest_sha256" => photo_digest)

            photo_digest = Digest::SHA512.file(photo_target_file)
            photo_digest = photo_digest.hexdigest
            photo_digest = photo_digest.to_s()
            barf("Photo digest (SHA512): " + photo_digest, 3)
            photo_size_map = photo_size_map.merge!("digest_sha512" => photo_digest)

            barf("Photo size label: " + flickr_photo_sizes.label, 3)
            photo_size_map = photo_size_map.merge!("label" => flickr_photo_sizes.label)

            barf("Photo size width: " + flickr_photo_sizes.width.to_s, 3)
            photo_size_map = photo_size_map.merge!("width" => flickr_photo_sizes.width)

            barf("Photo size height: " + flickr_photo_sizes.height.to_s, 3)
            photo_size_map = photo_size_map.merge!("height" => flickr_photo_sizes.height)

            photo_sizes_map = photo_sizes_map.merge!(size => photo_size_map)

            ##sleep 1
        end
        photo_map = photo_map.merge!("photo_sizes" => photo_sizes_map)

        photo = photo - 1

        #barf(photo_map.to_json, 3)
        #barf(JSON.pretty_generate(photo_map), 3)
        File.open(photo_cache_dir + "/meta.json", 'wb') {|f| f.write(JSON.pretty_generate(photo_map))}
        ##exit
        ##sleep 1
    end

    page = page + 1
    ##sleep 1
end

##puts(overall_tags.sort)
##puts(JSON.pretty_generate(overall_tags.sort))

barf("Finished...!", 2)
