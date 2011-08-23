require 'sinatra/base'
require 'digest/sha2'
require 'audioinfo'

module Qtunes
  class Server < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true

    get '/' do
      @song = PLAYER.file
      @songs = queue

      erb :songs
    end
    
    get '/library' do
      @song = PLAYER.file
      @songs = library

      erb :songs
    end

    get '/add/:id' do
      PLAYER.enqueue(library[params[:id]][:path])

      redirect '/'
    end

    get '/remove/:id' do
      ix = library.keys.index(params[:id])

      # badass!
      PLAYER.view_queue
      PLAYER.win_top
      ix.times{ PLAYER.win_down }
      PLAYER.win_remove
      
      redirect '/'
    end

    configure do
      puts "Configure"

      PLAYER = Qtunes::Player.new
    end

    protected
      def queue
        PLAYER.queue.inject({}) do |res,path|
          begin
            song = {:path => path}.merge(AudioInfo.open(path).to_h)
          rescue AudioInfoError
            next res
          end
          res[song_id(path)] = song
          res
        end
      end

      def library
        @library ||= PLAYER.library.inject({}) do |res,path|
          begin
            song = {:path => path}.merge(AudioInfo.open(path).to_h)
          rescue AudioInfoError
            next res
          end
          res[song_id(path)] = song
          res
        end
      end

      def song_id(file)
        Digest::SHA256.hexdigest(file)[0,10]
      end
  end
end
