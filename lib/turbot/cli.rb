load('turbot/helpers.rb') # reload helpers after possible inject_loadpath
load('turbot/updater.rb') # reload updater after possible inject_loadpath

require "turbot"
require "turbot/command"
require "turbot/helpers"

# workaround for rescue/reraise to define errors in command.rb failing in 1.8.6
if RUBY_VERSION =~ /^1.8.6/
  require('turbot-api')
  require('rest_client')
end

class Turbot::CLI

  extend Turbot::Helpers

  def self.start(*args)
    begin
      if $stdin.isatty
        $stdin.sync = true
      end
      if $stdout.isatty
        $stdout.sync = true
      end
      command = args.shift.strip rescue "help"
      Turbot::Command.load
      Turbot::Command.run(command, args)
    rescue Interrupt
      `stty icanon echo`
      error("Command cancelled.")
    rescue => error
      styled_error(error)
      exit(1)
    end
  end

end
