require 'sinatra/base'
require 'digest/sha2'

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
      PLAYER.enqueue(library[params[:id]])

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
        PLAYER.queue.inject({}){|res,file| res[song_id(file)]=file; res}
      end

      def library
        @library ||= PLAYER.library.inject({}){|res,file| res[song_id(file)]=file; res}
      end

      def song_id(file)
        Digest::SHA256.hexdigest(file)[0,10]
      end
  end
end