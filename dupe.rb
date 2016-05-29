require 'phashion'
require 'pathname'
require 'peach'
require 'facter'
require 'json'
require 'exifr'

CONCURRENCY = [Facter.value('processors')['count'] - 1, 1].max

fail 'needs path to images' unless ARGV[0]

images = Pathname.glob(ARGV[0] + "/**.jpg").map do |file|
  Phashion::Image.new file.to_s
end

duplicates = images.repeated_combination(2).pmap(CONCURRENCY) do |a ,b|
  next if a === b

  if a.duplicate?(b)
    {
      a: a.filename,
      b: b.filename,
      result: nil
    }
  end
end.compact

puts duplicates.map { |dupe|
    a_exif = EXIFR::JPEG.new(dupe[:a])
    b_exif = EXIFR::JPEG.new(dupe[:b])

    # just choose largest for now...
    dupe[:result] = if (a_exif.width * a_exif.height) > (b_exif.width * b_exif.height)
                      { winner: dupe[:a], loser: dupe[:b] }
    else
                      { winner: dupe[:b], loser: dupe[:a] }
    end

    dupe
}.to_json
