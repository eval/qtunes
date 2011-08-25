require 'sinatra/base'
require 'digest/sha2'
require 'audioinfo'

module Paginatable
  def self.included(base)
    base.extend(ClassMethods)
  end

  def page(n)
    slice(*[n - 1, 1].map{|i| i * self.per_page }) || []
  end

  def per_page
    self.class.per_page
  end

  module ClassMethods
    def per_page
      10
    end
  end
end

class Array
  include Paginatable
end

module Qtunes
  class Server < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true

    get '/' do
      @song = player.file
      @songs = queue

      erb :songs
    end
    
    get '/library' do
      @page = params[:page] ? params[:page].to_i : 1
      @song = player.file
      @songs = library.values.page(@page)

      erb :songs
    end

    get '/add/:id' do
      player.enqueue(library[params[:id]]['path'])
      player.play if not player.playing?

      redirect '/'
    end

    get '/remove/:id' do
      ix = library.keys.index(params[:id])

      # badass!
      player.view_queue
      player.win_top
      ix.times{ player.win_down }
      player.win_remove
      
      redirect '/'
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

    protected
      def self.songs_to_hash
        yield.inject({}) do |res,path|
          begin
            song = AudioInfo.open(path).to_h
          rescue AudioInfoError
            next res
          end
          res[song_id(path)] = song.merge('path' => path, 'id' => song_id(path))
          res
        end
      end

      def self.song_id(file)
        Digest::SHA256.hexdigest(file)[0,10]
      end

    configure do
      puts "Configure"

      Qtunes::Server.library
    end
  end
end
