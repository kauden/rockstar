# Getting information about an album such as release date and the summary or description on it is very easy.
#
#   album = Rockstar::Album.new('Carrie Underwood', 'Some Hearts', include_info: true)
#
#   puts "Album: #{album.name}"
#   puts "Artist: #{album.artist}"
#   puts "URL: #{album.url}"
#   puts "Release Date: #{album.release_date.strftime('%m/%d/%Y')}"
#
# Would output:
#
#   Album: Some Hearts
#   Artist: Carrie Underwood
#   URL: http://www.last.fm/music/Carrie+Underwood/Some+Hearts
#   Release Date: 11/15/2005
#
module Rockstar
  class Album < Base
    attr_accessor :artist, :artist_mbid, :name, :mbid, :playcount, :rank, :url, :release_date, :id, :image_extralarge
    attr_accessor :image_large, :image_medium, :image_small, :summary, :content, :images, :tracks, :tags, :image_mega

    # needed on top albums for tag
    attr_accessor :count, :streamable

    # needed for weekly album charts
    attr_accessor :chartposition

    class << self
      def find(artist, name, o={})
        new(artist, name, o)
      end

      def new_from_xml(xml, doc=nil)
        name             = (xml).at(:name).inner_html                  if (xml).at(:name)
        name             = xml['name']                                 if name.nil? && xml['name']
        name             = xml.at(:title).inner_html                   if name.nil? && (xml).at(:title)
        artist           = (xml).at(:artist).at(:name).inner_html      if (xml).at(:artist) && (xml).at(:artist).at(:name)
        artist           = (xml).at(:artist).inner_html                if artist.nil? && (xml).at(:artist)
        artist           = doc.root['artist']                          if artist.nil? && doc && doc.root['artist']

        album = Album.new(artist, name)
        album.load_info(xml)
        album
      end
    end

    def initialize(mbid, o={})
      #raise ArgumentError, "Artist is required" if artist.blank?
      raise ArgumentError, "mbid is required" if mbid.blank?
      @mbid = mbid

      options = {include_info: false}.merge(o)

      @artist = options[:artist].present? ? options[:artist] : nil
      @name = options[:name].present? ? options[:name] : nil
      
      load_info if options[:include_info]
    end

    def load_info(xml=nil)
      unless xml
        if @artist.present?
          doc = self.class.fetch_and_parse("album.getInfo", { artist: @artist, album: @name })
        else
          doc = self.class.fetch_and_parse("album.getInfo", { mbid: @mbid })
        end
        xml = (doc / :album).first
      end

      return self if xml.nil?

      self.artist_mbid    = (xml).at(:artist)['mbid']                   if (xml).at(:artist) && (xml).at(:artist)['mbid']
      self.artist_mbid    = (xml).at(:artist).at(:mbid).inner_html      if artist_mbid.nil? && (xml).at(:artist) && (xml).at(:artist).at(:mbid)
      self.mbid           = (xml).at(:mbid).inner_html                  if (xml).at(:mbid)
      self.playcount      = (xml).at(:playcount).inner_html             if (xml).at(:playcount)
      self.rank           = xml['rank']                                 if xml['rank']
      self.rank           = (xml).at(:rank).inner_html                  if (xml).at(:rank) if rank.nil?
      self.url            = Base.fix_url((xml).at(:url).inner_html)     if (xml).at(:url)

      self.summary        = (xml).at(:summary).to_plain_text            if (xml).at(:summary)
      self.content        = (xml).at(:content).to_plain_text            if (xml).at(:content)

      self.release_date   = Base.parse_time((xml).at(:releasedate).inner_html.strip) if (xml).at(:releasedate)
      self.chartposition  = rank

      self.images = {}
      (xml/'image').each {|image|
        self.images[image['size']] = image.inner_html if self.images[image['size']].nil?
      }

      self.image_large      = images['large']
      self.image_medium     = images['medium']
      self.image_small      = images['small']
      self.image_extralarge = images['extralarge']
      self.image_mega       = images['mega']

      # needed on top albums for tag
      self.count          = xml['count'] if xml['count']
      self.streamable     = xml['streamable'] if xml['streamable']

      list_tracks = []
      track_number = 1
      (xml/'tracks/track').collect do |track|
        name = (track).at(:name).present? ? (track).at(:name).inner_html : nil
        duration = (track).at(:duration).present? ? (track).at(:duration).inner_html.to_i : nil
        url = (track).at(:url).present? ? Base.fix_url((track).at(:url).inner_html) : nil
        list_tracks << {
          track_number: track_number, 
          name: name, 
          duration: duration,
          url: url
        }
        track_number = track_number + 1
      end

      self.tracks = list_tracks

      list_tags = []
      (xml/'toptags/tag').collect do |tag|
        name = (tag).at(:name).present? ? (tag).at(:name).inner_html : nil
        list_tags << name
      end

      self.tags = list_tags

      self
    end

    def image(which=:small)
      which = which.to_s
      raise ArgumentError unless ['small', 'medium', 'large', 'extralarge', 'mega'].include?(which)
      if (self.images.nil?)
        load_info
      end
      self.images[which]
    end
  end
end
