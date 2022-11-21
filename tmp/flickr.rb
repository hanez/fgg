#
# https://www.flickr.com/services/api/
#

require 'adler32'
require 'digest'
require 'digest/crc32'
#require 'easy-crc'
require 'flickraw'
require 'openssl'

FlickRaw.api_key = ""
FlickRaw.shared_secret = ""

flickr.access_token = ""
flickr.access_secret = ""

def titleize(str)
  str.split(/ |\_/).map(&:capitalize).join(" ")
end

def get_count(f, pp, pl)
  # https://www.flickr.com/services/api/flickr.photos.getWithoutGeoData.html
  count = f.photos.getWithoutGeoData(:sort => 'date-taken-desc', :per_page => pp, :page => pl).length
end

login = flickr.test.login
puts "You are now authenticated as #{login.username}"

pp = 20
pl = 0
photo_count = 0
page_count = 0
print "Counting Pages...\n"
while get_count(flickr, pp, pl) != 0 do
  pl = pl + 1
  c = get_count(flickr, pp, pl)
  photo_count = photo_count + c
    print "."
    STDOUT.flush
end
page_count = pl - 1
print "\n"
print "Counted: " + page_count.to_s() + " pages..."
print "\n"
print "Counted: " + photo_count.to_s() + " photos..."
print "\n"

tmp_page1 = 1
paging_code1 = "<h2 style=\"clear: both;\">Pages</h2><div id=\"pages\">"
while tmp_page1 <= page_count do
    if tmp_page1 < 2
        paging_code1 = paging_code1 + "<a href=\"/photos/\" class=\"active\" title=\"Page: 1\">1</a>"
    else
        paging_code1 = paging_code1 + "<a href=\"/photos/" + tmp_page1.to_s + "/\" title=\"Page: " + tmp_page1.to_s + "\">" + tmp_page1.to_s + "</a>"
    end
    tmp_page1 = tmp_page1 + 1
    #print "."
    #STDOUT.flush
end
paging_code1 = paging_code1 + "</div>"


puts "Creating Pages...\n"
page = 1

while page <= page_count do
    #print "Creating Pagination... for page" + page.to_s + "\n"
    print "Page: " + page.to_s + "\n"
    tmp_page = 1
    paging_code = "<h2 style=\"clear: both;\">Pages</h2><div id=\"pages\">"
    while tmp_page <= page_count do
        if tmp_page == page
            paging_code = paging_code + "<a href=\"/photos/" + tmp_page.to_s + "/\" class=\"active\" title=\"Page: " + tmp_page.to_s + "\">" + tmp_page.to_s + "</a>"
        elsif tmp_page != page
            paging_code = paging_code + "<a href=\"/photos/" + tmp_page.to_s + "/\" title=\"Page: " + tmp_page.to_s + "\">" + tmp_page.to_s + "</a>"
        end
        tmp_page = tmp_page + 1
        #print "."
        STDOUT.flush
    end
    paging_code = paging_code + "</div>"
    #print "\n"

    #print "."
    #STDOUT.flush

    # https://www.flickr.com/services/api/flickr.photos.getWithoutGeoData.html
    list = flickr.photos.getWithoutGeoData(:sort => 'date-taken-desc', :per_page => pp, :page => page)

    h_cmd = ""
    if page < 2
        h_cmd = "mkdir -p photos/" + page.to_s + "; "
        h_cmd = h_cmd + "echo '---\nlayout: photos\nstatus: publish\npublished: true\nnoToc: true\ntitle: Photos\n---\n' > photos/index.html; "
        h_cmd = h_cmd + "echo '---\nlayout: photos\nstatus: publish\npublished: true\nnoToc: true\ntitle: Photos\n---\n' > photos/1/index.html; "
        h_cmd = h_cmd + "echo '<div id=\"photos\"><ul>' >> photos/index.html; "
        h_cmd = h_cmd + "echo '<div id=\"photos\"><ul>' >> photos/1/index.html; "
    else
        h_cmd = "mkdir -p photos/" + page.to_s + "; "
                h_cmd = h_cmd + "echo '---\nlayout: photos\nstatus: publish\npublished: true\nnoToc: true\ntitle: Photos\n---\n' > photos/" + page.to_s + "/index.html; "
        h_cmd = h_cmd + "echo '<div id=\"photos\"><ul>' >> photos/" + page.to_s + "/index.html; "
    end

    wasGood = system( h_cmd )

    list.each_with_index do
      |vv, ii|

      m_cmd = "mkdir -p _cache/photos/" + vv.id
      wasGood = system( m_cmd )

      if File.file?("_cache/photos/" + vv.id + "/.meta")
        info = Marshal.load(File.binread("_cache/photos/" + vv.id + "/.meta"))
      else
        # https://www.flickr.com/services/api/flickr.photos.getInfo.html
        info = flickr.photos.getInfo(:photo_id => vv.id)
        File.open("_cache/photos/" + vv.id + "/.meta", 'wb') {|f| f.write(Marshal.dump(info))}
      end

      tmpfilename2 = info.title.tr("\s", "_")
      tmpfilename3 = String.new(tmpfilename2.delete("\'\"\.\s\,\!\/\:\(\)\[\]\;\?\&\<\>"))
      filename = tmpfilename3.tr("__", "_")
      ##filename = filename.to_s()
      ##filename = filename.gsub("__", "_")

      # NEVER CHANGE THE FOLLOWING LINES (UNTIL "# END") EXPECT YOU REALLY
      # WANT OR NEED TO CHANGE THE PHOTO ID!!! ALL LINKS TO THIS IMAGE WILL
      # BECOME BROKEN!!! - hanez
      # https://docs.ruby-lang.org/en/master/OpenSSL/Digest.html
      digest1 = OpenSSL::Digest.new('sha256', vv.id.to_s + info.dates.taken.to_s())
      digest2 = OpenSSL::Digest.new('sha512', vv.id.to_s + info.dates.taken.to_s())
      digest3 = OpenSSL::Digest.new('sha3-256', vv.id.to_s + info.dates.taken.to_s())
      digest4 = OpenSSL::Digest.new('sha3-512', vv.id.to_s + info.dates.taken.to_s())

      id_new = Digest::CRC32c.hexdigest(digest1.to_s() + digest2.to_s() + digest3.to_s() + digest4.to_s())

      # check if photo exists because of a hash collusion create an alternative but stable crc
      # the next lines does not working when updating the gallery; a fresh gallery wil be needed.
      #if File.file?("photo/" + id_new + "/index.html")
      #  id_new = Digest::CRC32c.hexdigest(digest1.to_s() + digest2.to_s() + digest3.to_s() + digest4.to_s() + digest4.to_s())
      #else
      #
      #end

      # https://github.com/postmodern/digest-crc
      # https://rubydoc.info/gems/digest-crc

      # https://github.com/sakatam/adler32-ruby
      # https://www.rubydoc.info/gems/adler32/0.0.2
      #id_old = Adler32.checksum('{}', vv.id.to_s(), filename.to_s(), info.title.to_s(), info.dates.taken.to_s())
      #id_old = id_old.to_s()
      id_new = id_new.to_s()
      # END

      m_cmd = "mkdir -p photo/" + id_new
      wasGood = system( m_cmd )

      t_cmd = "echo '---\nlayout: photo\nstatus: publish\npublished: true\n' > photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo 'title: \"" + info.title + "\"' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo 'description: \"" + info.title + "\"' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo 'date: " + info.dates.taken + "' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo 'flickr: " + vv.id + "' >> photo/" + id_new + "/index.html; "
      #t_cmd = t_cmd + "echo 'tags: \"" + info.tags + "\"' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo '---\n\n' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo '<!-- fid: '" + vv.id + "' -->' >> photo/" + id_new + "/index.html; "
      #t_cmd = t_cmd + "echo '<!-- oid: '" + id_old + "' -->' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo '<!-- nid: '" + id_new + "' -->' >> photo/" + id_new + "/index.html; "
      t_cmd = t_cmd + "echo '<!-- cmd: rm -rf ./_cache/photos/'" + vv.id + "/' && rm -rf ./photo/'" + id_new + "/' -->' >> photo/" + id_new + "/index.html; "

      # 2004-11-19 12:51:19
      date_new = info.dates.taken
      date_new = date_new.to_s()
      date_new["-"] = ""
      date_new["-"] = ""
      date_new[" "] = ""
      date_new[":"] = ""
      date_new[":"] = ""

      if File.file?("photo/" + id_new + "/" + filename + "_l_" + date_new + ".jpg")
         t_cmd = t_cmd + "echo '<p style=\"text-align:center;\"><a href=\"/photo/" + id_new + "/" + filename + "_" + "l_" + date_new + ".jpg\" title=\"" + info.title + "\" data-lity data-lity-desc=\"" + info.title + "\"><img src=\"/photo/" + id_new + "/" + filename + "_" + "m_" + date_new + ".jpg\" alt=\"" + info.title + "\" class=\"x\"></a></p>' >> photo/" + id_new + "/index.html; "
      else
         t_cmd = t_cmd + "echo '<p style=\"text-align:center;\"><a href=\"/photo/" + id_new + "/" + filename + "_" + "o_" + date_new + ".jpg\" title=\"" + info.title + "\" data-lity data-lity-desc=\"" + info.title + "\"><img src=\"/photo/" + id_new + "/" + filename + "_" + "m_" + date_new + ".jpg\" alt=\"" + info.title + "\" class=\"x\"></a></p>' >> photo/" + id_new + "/index.html; "
      end

      if info.description.length > 100
        t_cmd = t_cmd + "echo '<p style=\"display:block;\">" + info.description + "</p>' >> photo/" + id_new + "/index.html; "
      else
        t_cmd = t_cmd + "echo '<p style=\"text-align:center;\">" + info.description + "</p>' >> photo/" + id_new + "/index.html; "
      end

      if page < 2
        t_cmd = t_cmd + "echo '<li><a href=\"/photo/" + id_new + "/\" title=\"" + info.title + "\"><img src=\"/photo/" + id_new + "/" + filename + "_" + "x_" + date_new + ".jpg\" alt=\"" + info.title + "\"><br /><span>" + info.title[0..30] + "...</span></a></li>' >> photos/index.html; "
        t_cmd = t_cmd + "echo '<li><a href=\"/photo/" + id_new + "/\" title=\"" + info.title + "\"><img src=\"/photo/" + id_new + "/" + filename + "_" + "x_" + date_new + ".jpg\" alt=\"" + info.title + "\"><br /><span>" + info.title[0..30] + "...</span></a></li>' >> photos/1/index.html; "
      else
        t_cmd = t_cmd + "echo '<li><a href=\"/photo/" + id_new + "/\" title=\"" + info.title + "\"><img src=\"/photo/" + id_new + "/" + filename + "_" + "x_" + date_new + ".jpg\" alt=\"" + info.title + "\"><br />" + info.title[0..30] + "...</a></li>' >> photos/" + page.to_s + "/index.html; "
      end

      t_cmd = t_cmd + "echo '<h2>All sizes</h2>\n\n<ul class=\"fa-ul\">' >> photo/" + id_new + "/index.html; "

      if File.file?("_cache/photos/" + vv.id + "/.sizes")
        sizes = Marshal.load(File.binread("_cache/photos/" + vv.id + "/.sizes"))
      else
        # https://www.flickr.com/services/api/flickr.photos.getSizes.html
        sizes = flickr.photos.getSizes(:photo_id => vv.id)
        File.open("_cache/photos/" + vv.id + "/.sizes", 'wb') {|f| f.write(Marshal.dump(sizes))}
      end

      sizes.each_with_index do
        |vvv, iii|

        x = vvv.url[-2, 1]
        if vvv.label == "Square"
          x = "x"
        end

        if File.file?("photo/" + id_new + "/" + filename + "_" + x + "_" + date_new + ".jpg")
          #p ">>> nothing to do... <3"
        else
          d_cmd = "wget -U Foo -O photo/" + id_new + "/" + filename + "_" + x + "_" + date_new + ".jpg " + vvv.source
          wasGood = `#{d_cmd}`
        end

        photo_digest = Digest::SHA1.file("photo/" + id_new + "/" + filename + "_" + x + "_" + date_new + ".jpg")
        photo_digest = photo_digest.hexdigest
        photo_digest = photo_digest.to_s()

        if vvv.label == "Small" or vvv.label == "Medium" or vvv.label == "Large" or vvv.label == "Original"
          t_cmd = t_cmd + "echo '<li><a href=\"/photo/" + id_new + "/" + filename + "_" + x + "_" + date_new + ".jpg\" title=\"" + info.title + " (Size: " + vvv.label + ")\"><i class=\"fa fa-image\" aria-hidden=\"true\" style=\"margin-right: 4px;\"></i>" + vvv.label + "</a> (SHA1: "+ photo_digest +")</li>' >> photo/" + id_new + "/index.html; "
        end

      end
      t_cmd = t_cmd + "echo '</ul>\n' >> photo/" + id_new + "/index.html; "

      #a_cmd = ""
      #if File.file?("photos/" + date_new +"_" + filename + "_" + id_new + ".7z")
        #p ">>> nothing to do... <3"
      #else
      #  a_cmd = a_cmd + "cd photo/" + id_new + "; 7z u ../../photos/" + date_new +"_" + filename + "_" + id_new + ".7z *.jpg ../../_extra/photos/LICENSE.txt; cd ../../;"
      #  wasGood = system( a_cmd )
      #end

      #archive_digest = Digest::SHA1.file("photos/" + date_new +"_" + filename + "_" + id_new + ".7z")
      #archive_digest = archive_digest.hexdigest
      #archive_digest = archive_digest.to_s()

      #t_cmd = t_cmd + "echo '<p><a href=\"/photos/" + date_new +"_" + filename + "_" + id_new + ".7z\" class=\"file\">Download full archive as 7z file</a> (SHA1: " + archive_digest + ")</p>' >> photo/" + id_new + "/index.html; "

      t_cmd = t_cmd + "echo '<h2>License</h2>\n' >> photo/" + id_new + "/index.html; "

      t_cmd = t_cmd + "echo '<p>This photo is licensed under a <a rel=\"license\" class=\"ext\" href=\"https://creativecommons.org/licenses/by-nc-sa/4.0/\">Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)</a> license. Please <a href=\"/contact.html\">contact</a> me if you want to use this photo for commercial purposes.</p>\n' >> photo/" + id_new + "/index.html; "

      ##t_cmd = t_cmd + "echo '<h2>Comments</h2>\n' >> photo/" + id_new + "/index.html; "
      ##t_cmd = t_cmd + "echo '<p>If you want to add a comment, you can do this using a Flickr account. The photos are synced regularly and your comment will at some time occour here. <a href=\"https://www.flickr.com/photos/johannesfindeisen/" + vv.id + "/\" class=\"ext\"><i class=\"fa fa-flickr\" aria-hidden=\"true\"></i> https://www.flickr.com/photos/johannesfindeisen/" + vv.id + "/</a>.</p>' >> photo/" + id_new + "/index.html; "

      wasGood = system( t_cmd )
      sleep 1
      t_cmd = ""
    end

    p_cmd = ""
    if page < 2
      p_cmd = p_cmd + "echo '</ul></div>' >> photos/index.html; "
      p_cmd = p_cmd + "echo '" + paging_code1 + "' >> photos/index.html; "
      p_cmd = p_cmd + "echo '</ul></div>' >> photos/" + page.to_s + "/index.html; "
      p_cmd = p_cmd + "echo '" + paging_code1 + "' >> photos/" + page.to_s + "/index.html; "
    else
      p_cmd = p_cmd + "echo '</ul></div>' >> photos/" + page.to_s + "/index.html; "
      p_cmd = p_cmd + "echo '" + paging_code + "' >> photos/" + page.to_s + "/index.html; "
    end
    wasGood = system( p_cmd )
    sleep 1
    p_cmd = ""

    page = page + 1
end

print "\n"
print "Finished...!\n"

