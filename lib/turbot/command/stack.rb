require "turbot/command/base"

module Turbot::Command

  # manage the stack for an app
  class Stack < Base

    # stack
    #
    # show the list of available stacks
    #
    #Example:
    #
    # $ turbot stack
    # === example Available Stacks
    #   bamboo-mri-1.9.2
    #   bamboo-ree-1.8.7
    # * cedar
    #
    def index
      validate_arguments!

      stacks_data = api.get_stack(app).body

      styled_header("#{app} Available Stacks")
      stacks = stacks_data.map do |stack|
        row = [stack['current'] ? '*' : ' ', stack['name']]
        row << '(beta)' if stack['beta']
        row << '(deprecated)' if stack['deprecated']
        row << '(prepared, will migrate on next git push)' if stack['requested']
        row.join(' ')
      end
      styled_array(stacks)
    end

    # stack:migrate STACK
    #
    # prepare migration of this app to a new stack
    #
    #Example:
    #
    # $ turbot stack:migrate cedar
    # -----> Preparing to migrate evening-warrior-2345
    #        bamboo-mri-1.9.2 -> bamboo-ree-1.8.7
    #
    #        NOTE: You must specify ALL gems (including Rails) in manifest
    #
    #        Please read the migration guide:
    #        http://devcenter.turbot.com/articles/bamboo
    #
    # -----> Migration prepared.
    #        Run 'git push turbot master' to execute migration.
    #
    def migrate
      unless stack = shift_argument
        error("Usage: turbot stack:migrate STACK.\nMust specify target stack.")
      end

      display(api.put_stack(app, stack).body)
    end
  end
end
