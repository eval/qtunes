require 'qtunes'
require 'sinatra/base'
require 'rack-flash'
require 'digest/sha2'
require 'audioinfo'
require 'qtunes/paginatable'
require 'compass'
require 'susy'

module Qtunes
  class Server < Sinatra::Base
    enable :sessions
    use Rack::Flash, :sweep => false

    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true

    before do
      @current = self.class.song_to_hash(player.file)
    end

    get '/screen.css' do
      require 'susy'
      content_type 'text/css', :charset => 'utf-8'
      scss :screen
    end

    get '/' do
      @songs = queue.values

      erb :songs
    end
    
    get '/library' do
      #@page = params[:page] ? params[:page].to_i : 1
      @artist = params[:artist] || 'a'
      #@songs = library.values.extend(Qtunes::Paginatable).page(@page)
      @songs = library_by_first_letter_of_artist[@artist] || []

      erb :songs
    end

    get '/add/:id' do
      player.enqueue(library[params[:id]]['path']) && flash[:notice] = "Song added"
      player.play if player.stopped?

      redirect back
    end

    get '/remove/:id' do
      ix = queue.keys.index(params[:id])

      # badass!
      player.view_queue
      player.win_top
      ix.times{ player.win_down }
      player.win_remove && flash[:notice] = "Song removed"

      redirect back
    end

    def self.player
      @player ||= Qtunes::Player.new
    end

    def player
      self.class.player
    end

    def self.queue
      songs_to_hash{ player.queue }
    end

    def queue
      self.class.queue
    end

    def self.library_by_first_letter_of_artist
      @library_by_first_letter_of_artist ||= begin
        result = Hash.new{|h,k| h[k] = Array.new }
        library.values.inject(result) do |res,song| 
          key = song['artist'] ? string_to_ascii(song['artist']).downcase[0,1] : ''
          res[key] << song
          res
        end
      end
    end

    def library_by_first_letter_of_artist
      self.class.library_by_first_letter_of_artist
    end

    def self.library
      @library ||= begin
        print "Loading library..."
        result = songs_to_hash{ player.library }
        puts "Done"
        result
      end
    end

    def library
      self.class.library
    end

    def self.string_to_ascii(s)
      require 'unicode'
      Unicode::normalize_KD(s).gsub(/[^A-Za-z0-9\s_-]+/,'')
    end

    def string_to_ascii(s)
      self.class.string_to_ascii(s)
    end

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html
    end

    protected
      def self.songs_to_hash
        yield.inject({}) do |res,path|
          res[song_id(path)] = song_to_hash(path)
          res
        end
      end

      def self.song_id(path)
        Digest::SHA256.hexdigest(path)[0,10]
      end


      # Get the information for a song.
      #
      # path  - String representing location of song
      #
      # Examples
      #
      #   song_to_hash '~/Music/song2.mp3'
      #   # => {'path' => '~/Music/song2.mp3', 'id' => '12345', ...}
      #
      # Returns Hash with info of song or empty Hash in case path is nil.
      def self.song_to_hash(path)
        result = {}

        return result if not path

        begin
          result.merge!(AudioInfo.open(path).to_h)
        rescue AudioInfoError
        end
        result.merge!('path' => path, 'id' => song_id(path))
        result
      end

      def debug(object)
        begin
          Marshal::dump(object)
          "<pre class='debug_dump'>#{h(object.to_yaml).gsub("  ", "&nbsp; ")}</pre>"
        rescue Exception => e  # errors from Marshal or YAML
          # Object couldn't be dumped, perhaps because of singleton methods -- this is the fallback
          "<code class='debug_dump'>#{h(object.inspect)}</code>"
        end
      end

    configure do
      puts "Configure"

      Compass.configuration do |config|
        config.project_path = dir
        config.sass_dir = "#{dir}/server/views"
      end
      set :scss, Compass.sass_engine_options

      Qtunes::Server.library
    end
  end
end
