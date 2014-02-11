# Below are examples of how to find an artists top tracks and similar artists.
#
#   artist = Rockstar::Artist.new('Carrie Underwood')
#
#   puts 'Top Tracks'
#   puts "=" * 10
#   artist.top_tracks.each { |t| puts "#{t.name}" }
#
#   puts
#
#   puts 'Similar Artists'
#   puts "=" * 15
#   artist.similar.each { |a| puts "(#{a.match}%) #{a.name}" }
#
# Would output something similar to:

module Rockstar
  class Search < Base
    attr_accessor :name, :mbid, :listenercount, :playcount, :rank, :url, :thumbnail
    attr_accessor :summary, :content, :images, :count, :streamable, :albummatches
    attr_accessor :chartposition

    # used for similar artists
    attr_accessor :match

    class << self
      def new_from_xml(xml, doc=nil)
        # occasionally name can be found in root of artist element (<artist name="">) rather than as an element (<name>)
        name             = (xml).at(:name).inner_html           if (xml).at(:name)
        name             = xml['name']                          if name.nil? && xml['name']
      end
    end

    def initialize(name, o={})
      raise ArgumentError, "Name or mbid is required" if name.blank? && o[:mbid].blank?
      @name = name unless name.blank?
      @mbid = o[:mbid] unless o[:mbid].blank?

      options = {:include_info => false}.merge(o)
      load_info if options[:include_info]
    end

    def load_info(xml=nil)
      unless xml
        params = @mbid.blank? ? {:album => @name} : {:mbid => @mbid}

        doc = self.class.fetch_and_parse("album.search", params)
        xml = (doc / :results).first
      end

      return self if xml.nil?

      self.albummatches = (xml/'album/name').collect(&:inner_html)
      self.albummatchesa = (xml/'album')
      self.albummatchesb = (xml/'album').collect{ |s| {name: s.name, artist: s.artist, id: s.id} }

      self
    end

  end
end
