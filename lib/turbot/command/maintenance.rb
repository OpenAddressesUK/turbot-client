require "turbot/command/base"

# manage maintenance mode for an app
#
class Turbot::Command::Maintenance < Turbot::Command::Base

  # maintenance
  #
  # display the current maintenance status of app
  #
  #Example:
  #
  # $ turbot maintenance
  # off
  #
  def index
    validate_arguments!

    case api.get_app_maintenance(app).body['maintenance']
    when true
      display('on')
    when false
      display('off')
    end
  end

  # maintenance:on
  #
  # put the app into maintenance mode
  #
  #Example:
  #
  # $ turbot maintenance:on
  # Enabling maintenance mode for example
  #
  def on
    validate_arguments!

    action("Enabling maintenance mode for #{app}") do
      api.post_app_maintenance(app, '1')
    end
  end

  # maintenance:off
  #
  # take the app out of maintenance mode
  #
  #Example:
  #
  # $ turbot maintenance:off
  # Disabling maintenance mode for example
  #
  def off
    validate_arguments!

    action("Disabling maintenance mode for #{app}") do
      api.post_app_maintenance(app, '0')
    end
  end

end
