require 'qtunes'
require 'sinatra/base'
require 'rack-flash'
require 'digest/sha2'
require 'audioinfo'
require 'qtunes/paginatable'

module Qtunes
  class Server < Sinatra::Base
    enable :sessions
    use Rack::Flash, :sweep => false

    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true

    before do
      @current = self.class.song_to_hash(player.file) rescue {}
    end

    get '/' do
      @songs = queue.values

      erb :songs
    end
    
    get '/library' do
      @page = params[:page] ? params[:page].to_i : 1
      @songs = library.values.extend(Qtunes::Paginatable).page(@page)

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

      def self.song_to_hash(path)
        result = {}
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

      Qtunes::Server.library
    end
  end
end
