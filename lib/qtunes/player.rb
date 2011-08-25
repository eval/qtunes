require 'cocaine'
require 'shellwords'

module Qtunes
  class Player
    INFO_KEYS = %w(status file duration position)
    
    def info_raw
      execute("status").split("\n")
    end

    def info
      info_raw.inject({}) do |res,i|
        k,v = i.split(" ", 2)
        res[k] = v if INFO_KEYS.include?(k)
        res
      end
    end

    # The current state of the player.
    #
    # Examples
    #
    #   player = Qtunes::Player.new
    #   player.status
    #   # => 'playing'
    #
    # returns String, being one of: 'playing', 'paused', 'stopped'.
    def status
      info['status']
    end

    def playing?
      status == 'playing'
    end

    def stopped?
      status == 'stopped'
    end

    def paused?
      status == 'paused'
    end

    def file
      info['file']
    end

    def view_queue
      execute('view queue')
    end

    def win_top
      execute('win-top')
    end

    def win_down
      execute('win-down')
    end

    def win_remove
      execute('win-remove')
    end

    def play
      execute('player-play')
    end

    def stop
      execute('player-stop')
    end

    def pause
      execute('player-pause')
    end

    def next
      execute('player-next')
    end

    def prev
      execute('player-prev')
    end

    def enqueue(file)
      Cocaine::CommandLine.new('cmus-remote', "-q #{file.shellescape}").run
    end

    def queue
      execute('save -q -').split("\n")
    end

    def library
      execute('save -l -').split("\n")
    end

    def execute(command)
      Cocaine::CommandLine.new('cmus-remote', '-C :command', :command => command).run
    end
  end
end
