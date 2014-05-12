require "spec_helper"
require "turbot/command/base"

module Turbot::Command
  describe Base do
    before do
      @base = Base.new
      @base.stub!(:display)
      @client = mock('turbot client', :host => 'turbot.com')
    end

    describe "confirming" do
      it "confirms the app via --confirm" do
        Turbot::Command.stub(:current_options).and_return(:confirm => "example")
        @base.stub(:app).and_return("example")
        @base.confirm_command.should be_true
      end

      it "does not confirms the app via --confirm on a mismatch" do
        Turbot::Command.stub(:current_options).and_return(:confirm => "badapp")
        @base.stub(:app).and_return("example")
        lambda { @base.confirm_command}.should raise_error CommandFailed
      end

      it "confirms the app interactively via ask" do
        @base.stub(:app).and_return("example")
        @base.stub(:ask).and_return("example")
        Turbot::Command.stub(:current_options).and_return({})
        @base.confirm_command.should be_true
      end

      it "fails if the interactive confirm doesn't match" do
        @base.stub(:app).and_return("example")
        @base.stub(:ask).and_return("badresponse")
        Turbot::Command.stub(:current_options).and_return({})
        capture_stderr do
          lambda { @base.confirm_command }.should raise_error(SystemExit)
        end.should == <<-STDERR
 !    Confirmation did not match example. Aborted.
STDERR
      end
    end

    context "detecting the app" do
      it "attempts to find the app via the --app option" do
        @base.stub!(:options).and_return(:app => "example")
        @base.app.should == "example"
      end

      it "attempts to find the app via the --confirm option" do
        @base.stub!(:options).and_return(:confirm => "myconfirmapp")
        @base.app.should == "myconfirmapp"
      end

      it "attempts to find the app via HEROKU_APP when not explicitly specified" do
        ENV['HEROKU_APP'] = "myenvapp"
        @base.app.should == "myenvapp"
        @base.stub!(:options).and_return([])
        @base.app.should == "myenvapp"
        ENV.delete('HEROKU_APP')
      end

      it "overrides HEROKU_APP when explicitly specified" do
        ENV['HEROKU_APP'] = "myenvapp"
        @base.stub!(:options).and_return(:app => "example")
        @base.app.should == "example"
        ENV.delete('HEROKU_APP')
      end

      it "read remotes from git config" do
        Dir.stub(:chdir)
        File.should_receive(:exists?).with(".git").and_return(true)
        @base.should_receive(:git).with('remote -v').and_return(<<-REMOTES)
staging\tgit@turbot.com:example-staging.git (fetch)
staging\tgit@turbot.com:example-staging.git (push)
production\tgit@turbot.com:example.git (fetch)
production\tgit@turbot.com:example.git (push)
other\tgit@other.com:other.git (fetch)
other\tgit@other.com:other.git (push)
        REMOTES

        @turbot = mock
        @turbot.stub(:host).and_return('turbot.com')
        @base.stub(:turbot).and_return(@turbot)

        # need a better way to test internal functionality
        @base.send(:git_remotes, '/home/dev/example').should == { 'staging' => 'example-staging', 'production' => 'example' }
      end

      it "gets the app from remotes when there's only one app" do
        @base.stub!(:git_remotes).and_return({ 'turbot' => 'example' })
        @base.stub!(:git).with("config turbot.remote").and_return("")
        @base.app.should == 'example'
      end

      it "accepts a --remote argument to choose the app from the remote name" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'example-staging', 'production' => 'example' })
        @base.stub!(:options).and_return(:remote => "staging")
        @base.app.should == 'example-staging'
      end

      it "raises when cannot determine which app is it" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'example-staging', 'production' => 'example' })
        lambda { @base.app }.should raise_error(Turbot::Command::CommandFailed)
      end
    end

  end
end
