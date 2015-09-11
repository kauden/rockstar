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
    attr_accessor :name, :mbid, :albummatches, :images, :totalResults, :startIndex, :itemsPerPage

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
      @page = o[:page] unless o[:page].blank?
      @limit = o[:limit] unless o[:limit].blank?

      options = {:include_info => false}.merge(o)
      load_info if options[:include_info]
    end

    def load_info(xml=nil)
      unless xml
        params = @mbid.blank? ? {:album => @name} : {:mbid => @mbid}
        params.merge!(page: @page) if @page.present?
        params.merge!(limit: @limit) if @limit.present?

        doc = self.class.fetch_and_parse("album.search", params)
        xml = (doc / :results).first
      end

      return self if xml.nil?

      self.totalResults = (xml).at('opensearch:totalResults').inner_html.to_i if (xml).at('opensearch:totalResults')
      self.startIndex   = (xml).at('opensearch:startIndex').inner_html.to_i   if (xml).at('opensearch:startIndex')
      self.itemsPerPage = (xml).at('opensearch:itemsPerPage').inner_html.to_i if (xml).at('opensearch:itemsPerPage')

      list_album = []
      (xml/'albummatches/album').collect do |album|
        self.images = {}
        (album/'image').each do |image|
          self.images[image['size']] = image.inner_html if self.images[image['size']].nil?
        end
        image_small = images['small'].present? ? images['small'] : nil
        image_medium = images['medium'].present? ? images['medium'] : nil
        image_large = images['large'].present? ? images['large'] : nil
        image_extralarge = images['extralarge'].present? ? images['extralarge'] : nil
        id = (album).at(:id).present? ? (album).at(:id).inner_html : nil
        mbid = (album).at(:mbid).present? ? (album).at(:mbid).inner_html : nil
        name = (album).at(:name).present? ? (album).at(:name).inner_html : nil
        artist = (album).at(:artist).present? ? (album).at(:artist).inner_html : nil
        url = (album).at(:url).present? ? (album).at(:url).inner_html : nil
        list_album << {
          id: id, 
          mbid: mbid,
          name: name, 
          artist: artist,
          url: url,
          image_small: image_small,
          image_medium: image_medium,
          image_large: image_large,
          image_extralarge: image_extralarge
        }
      end

      self.albummatches = list_album

      self
    end

    def image(which=:small)
      which = which.to_s
      raise ArgumentError unless ['small', 'medium', 'large', 'extralarge'].include?(which)
      self.images[which]
    end

  end
end
