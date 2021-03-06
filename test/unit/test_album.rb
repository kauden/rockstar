require File.expand_path('../../test_helper.rb', __FILE__)

class TestAlbum < Test::Unit::TestCase
  def setup
    @album = Rockstar::Album.new('Carrie Underwood', 'Some Hearts')
  end
  
  test 'should require the artist name' do
    assert_raises(ArgumentError) { Rockstar::Album.new('', 'Some Hearts') }
  end
  
  test 'should require the track name' do
    assert_raises(ArgumentError) { Rockstar::Album.new('Carrie Underwood', '') }
  end
  
  test 'should know the artist' do
    assert_equal('Carrie Underwood', @album.artist)
  end
  
  test "should know it's name" do
    assert_equal('Some Hearts', @album.name)
  end
  
  test 'should be able to load album info' do
    @album.load_info
    assert_equal('http://www.last.fm/music/Carrie+Underwood/Some+Hearts', @album.url)
    assert_equal(Time.mktime(2005, 11, 15, 00, 00, 00), @album.release_date)
    assert_match(/debut album from fourth-season American Idol winner/, @album.summary)
  end

  test 'should be able to find an ablum' do
    album = Rockstar::Album.find('Carrie Underwood', 'Some Hearts')
    assert_equal('Carrie Underwood', album.artist)
    assert_equal('Some Hearts', album.name)
  end
  
  test "should be able to find an ablum and load the album's info" do
    album = Rockstar::Album.find('Carrie Underwood', 'Some Hearts', include_info: true)
    assert_equal('Carrie Underwood', album.artist)
    assert_equal('Some Hearts', album.name)
    assert_equal('http://www.last.fm/music/Carrie+Underwood/Some+Hearts', album.url)
    assert_equal(Time.mktime(2005, 11, 15, 00, 00, 00), album.release_date)
    assert_match(/debut album from fourth-season American Idol winner/, album.summary)
  end
  
  test "should be able to request detailed album info on initialize" do
    album = Rockstar::Album.new('Carrie Underwood', 'Some Hearts', include_info: true)
    assert_equal('Carrie Underwood', album.artist)
    assert_equal('Some Hearts', album.name)
    assert_equal('http://www.last.fm/music/Carrie+Underwood/Some+Hearts', album.url)
    assert_equal(Time.mktime(2005, 11, 15, 00, 00, 00), album.release_date)
    assert_match(/debut album from fourth-season American Idol winner/, album.summary)
  end
  
  test 'should have an image method that accepts a type' do
    @album.load_info
    assert_equal('http://userserve-ak.last.fm/serve/34s/34894445.png', @album.image(:small))
    assert_equal('http://userserve-ak.last.fm/serve/64s/34894445.png', @album.image(:medium))
    assert_equal('http://userserve-ak.last.fm/serve/174s/34894445.png', @album.image(:large))
  end
  
  test "should raise an argument error when attempting to get an image that doesn't exist" do
    @album.load_info
    assert_raises(ArgumentError) { @album.image(:fake) }
  end
  
  test 'should load info when trying to access an image if the info has not been loaded' do
    assert_equal('http://userserve-ak.last.fm/serve/34s/34894445.png', @album.image(:small))
  end

  test 'should parse empty album' do
    album = Rockstar::Album.new('Thievery Corporation', 'Radio Retalation')
    album.load_info
    assert_nil album.summary
  end
end
