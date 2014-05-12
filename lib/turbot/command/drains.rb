require "turbot/command/base"

module Turbot::Command

  # display syslog drains for an app
  #
  class Drains < Base

    # drains
    #
    # list all syslog drains
    #
    def index
      puts turbot.list_drains(app)
      return
    end

    # drains:add URL
    #
    # add a syslog drain
    #
    def add
      if url = args.shift
        puts turbot.add_drain(app, url)
        return
      else
        error("Usage: turbot drains:add URL")
      end
    end

    # drains:remove URL
    #
    # remove a syslog drain
    #
    def remove
      if url = args.shift
        puts turbot.remove_drain(app, url)
        return
      else
        error("Usage: turbot drains remove URL")
      end
    end

  end
end

