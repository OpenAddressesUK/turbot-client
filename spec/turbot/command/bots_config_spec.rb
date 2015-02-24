require "spec_helper"
require "turbot/command/bots"

describe Turbot::Command::Bots do
  describe 'config' do
    it 'receives config params' do
      envs = {
        'FOO': 'bar'
      }

      expect_any_instance_of(Turbot::API).to receive(:update).with('fakebot', nil, envs)

      #    execute Turbot::Command::Bots.config({'FOO' => 'bar'})
      execute "bots:config foo:bar"
    end
  end
end
