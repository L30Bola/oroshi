# encoding : utf-8
require 'mp3info'
# Engine to read and write tags from mp3 files

class TagsMp3Engine
  # Custom exceptions
  class Error < StandardError; end
  class ArgumentError < Error; end

  attr_reader :data

  def initialize(file)
    @file = file
    read_common_tags
  end

  # Meta-programming to read and write
  def method_missing(method, *args)
    is_set_method = (method.to_s =~ /(.*)=$/)
    key = is_set_method ? $1 : method.to_s
    # No such key
    super unless @data.has_key?(key)
    # Set
    return @data[key] = args[0] if is_set_method
    # Get
    return @data[key]
  end

  # Read common tags into @data
  def read_common_tags
    begin
      Mp3Info.open(@file) do |mp3info|
        @data = {
          'type'   => '',
          'genre'  => mp3info.tag.genre,
          'artist' => mp3info.tag.artist,
          'year'   => mp3info.tag.year.to_s,
          'album'  => mp3info.tag.album,
          'cd'     => mp3info.cd,
          'index'  => mp3info.tag.tracknum.to_s,
          'title'  => mp3info.tag.title,
        }
      end
    rescue
      # Unable to read the file as an mp3 file, we'll feed it empty 
      # metadata
      @data = {
        'type'   => '',
        'artist' => '', 
        'year' => '', 
        'album' => '', 
        'cd' => '',
        'index' => '',
        'title' => '' 
      }
    end
  end

  # Returns a TXXX array with only keys we want to keep
  def get_curated_txxx(mp3tags)
    return false unless mp3tags.TXXX
    # TXXX can sometime be a simple string, so we convert it to an array
    mp3tags.TXXX = [mp3tags.TXXX] if mp3tags.TXXX.is_a? String
    # Keeping only replaygain_ values
    mp3tags.TXXX.select() { |tag| tag =~ /^replaygain_/ }
  end

  # Update an mp3info.tag list to values passed in a hash
  def set_tags_to_file(mp3tags, hash)
    # We get the TXXX key that we need to keep (it contains replaygain values)
    txxx = get_curated_txxx(mp3tags)
    
    # Delete all tags that are not in the hash
    mp3tags.each do |tag, value|
      mp3tags[tag] = nil unless hash.has_key?(tag)
    end

    # Add every other key of hash that is not in the tag list
    hash.each do |key, value|
      mp3tags[key] = value
    end

    # We re-add the curated TXXX key if one is set
    mp3tags["TXXX"] = txxx if txxx
  end

  # Save tags back into file
  def save
    tag1 = {
      'artist' => @data['artist'],
      'year' => @data['year'],
      'album' => @data['album'],
      'tracknum' => @data['index'].to_i,
      'title' => @data['title']
    }
    tag2 = {
      'TPE1' => @data['artist'],
      'TYER' => @data['year'],
      'TALB' => @data['album'],
      'TPOS' => @data['cd'],
      'TRCK' => @data['index'],
      'TIT2' => @data['title']
    }

    # Predefined genres
    if @data['type'] == "podcasts"
      tag1['genre'] = 101 # There is no value for podcast in id3 v1, so we use "speech" instead
      tag2['TCON'] = "Podcast"
    end
    if @data['type'] == "soundtracks"
      tag1['genre'] = 24
      tag2['TCON'] = "Soundtrack"
    end

    puts "Rewriting id3 tags of #{File.basename(@file)}"
    Mp3Info.open(@file) do |mp3info|
      set_tags_to_file(mp3info.tag1, tag1)
      set_tags_to_file(mp3info.tag2, tag2)
    end

    # Mp3Info.open(@file) do |mp3info|
    #   puts "-----"
    #   puts "tag1 :"
    #   p mp3info.tag1
    #   puts "tag2 :"
    #   p mp3info.tag2
    #   puts "tag :"
    #   p mp3info.tag
    # end
  end

  


end

