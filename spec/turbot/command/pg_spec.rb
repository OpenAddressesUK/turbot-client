require "spec_helper"
require "turbot/command/pg"

module Turbot::Command
  describe Pg do
    before do
      stub_core

      api.post_app "name" => "example"
      api.put_config_vars "example", {
        "DATABASE_URL" => "postgres://database_url",
        "HEROKU_POSTGRESQL_IVORY_URL" => "postgres://database_url",
        "HEROKU_POSTGRESQL_RONIN_URL" => "postgres://ronin_database_url"
      }

      any_instance_of(Turbot::Helpers::TurbotPostgresql::Resolver) do |pg|
        stub(pg).app_attachments.returns([
          Turbot::Helpers::TurbotPostgresql::Attachment.new({
            'app' => {'name' => 'sushi'},
            'name' => 'HEROKU_POSTGRESQL_IVORY',
            'config_var' => 'HEROKU_POSTGRESQL_IVORY_URL',
            'resource' => {'name'  => 'loudly-yelling-1232',
                           'value' => 'postgres://database_url',
                           'type'  => 'turbot-postgresql:ronin' }}),
          Turbot::Helpers::TurbotPostgresql::Attachment.new({
            'app' => {'name' => 'sushi'},
            'name' => 'HEROKU_POSTGRESQL_RONIN',
            'config_var' => 'HEROKU_POSTGRESQL_RONIN_URL',
            'resource' => {'name'  => 'softly-mocking-123',
                           'value' => 'postgres://ronin_database_url',
                           'type'  => 'turbot-postgresql:ronin' }}),
          Turbot::Helpers::TurbotPostgresql::Attachment.new({
            'app' => {'name' => 'sushi'},
            'name' => 'HEROKU_POSTGRESQL_FOLLOW',
            'config_var' => 'HEROKU_POSTGRESQL_FOLLOW_URL',
            'resource' => {'name'  => 'whatever-somethign-2323',
                           'value' => 'postgres://follow_database_url',
                           'type'  => 'turbot-postgresql:ronin' }})
        ])
      end
    end

    after do
      api.delete_app "example"
    end

    it "resets the app's database if user confirms" do
      stub_pg.reset

      stderr, stdout = execute("pg:reset RONIN --confirm example")
      stderr.should == ""
      stdout.should == <<-STDOUT
Resetting HEROKU_POSTGRESQL_RONIN_URL... done
STDOUT
    end

    it "doesn't reset the app's database if the user doesn't confirm" do
      stub_pg.reset

      stderr, stdout = execute("pg:reset RONIN")
      stderr.should == <<-STDERR
 !    Confirmation did not match example. Aborted.
STDERR
      stdout.should == "
 !    WARNING: Destructive Action
 !    This command will affect the app: example
 !    To proceed, type \"example\" or re-run this command with --confirm example

> "
    end

    context "index" do
      it "requests the info from the server" do
        stub_pg.get_database.returns(:info => [
          {"name"=>"Plan", "values"=>["Ronin"]},
          {"name"=>"Status", "values"=>["available"]},
          {"name"=>"Data Size", "values"=>["1 MB"]},
          {"name"=>"Tables", "values"=>[1]},
          {"name"=>"PG Version", "values"=>["9.1.4"]},
          {"name"=>"Fork/Follow", "values"=>["Available"]},
          {"name"=>"Created", "values"=>["2011-12-13 00:00 UTC"]},
          {"name"=>"Maintenance", "values"=>["not required"]}
        ])

        stderr, stdout = execute("pg")
        stderr.should == ""
        stdout.should == <<-STDOUT
=== HEROKU_POSTGRESQL_FOLLOW_URL
Plan:        Ronin
Status:      available
Data Size:   1 MB
Tables:      1
PG Version:  9.1.4
Fork/Follow: Available
Created:     2011-12-13 00:00 UTC
Maintenance: not required

=== HEROKU_POSTGRESQL_IVORY_URL (DATABASE_URL)
Plan:        Ronin
Status:      available
Data Size:   1 MB
Tables:      1
PG Version:  9.1.4
Fork/Follow: Available
Created:     2011-12-13 00:00 UTC
Maintenance: not required

=== HEROKU_POSTGRESQL_RONIN_URL
Plan:        Ronin
Status:      available
Data Size:   1 MB
Tables:      1
PG Version:  9.1.4
Fork/Follow: Available
Created:     2011-12-13 00:00 UTC
Maintenance: not required

STDOUT
      end
    end

    context "info" do
      it "requests the info from the server" do
        stub_pg.get_database.returns(:info => [
          {"name"=>"Plan", "values"=>["Ronin"]},
          {"name"=>"Status", "values"=>["available"]},
          {"name"=>"Data Size", "values"=>["1 MB"]},
          {"name"=>"Tables", "values"=>[1]},
          {"name"=>"PG Version", "values"=>["9.1.4"]},
          {"name"=>"Fork/Follow", "values"=>["Available"]},
          {"name"=>"Forked From", "values"=>["postgres://username:password@postgreshost.com:5432/database_name"], "resolve_db_name" => "true"},
          {"name"=>"Created", "values"=>["2011-12-13 00:00 UTC"]},
          {"name"=>"Maintenance", "values"=>["not required"]}
        ])

        stderr, stdout = execute("pg:info RONIN")
        stderr.should == ""
        stdout.should == <<-STDOUT
=== HEROKU_POSTGRESQL_RONIN_URL
Plan:        Ronin
Status:      available
Data Size:   1 MB
Tables:      1
PG Version:  9.1.4
Fork/Follow: Available
Forked From: Database on postgreshost.com:5432/database_name
Created:     2011-12-13 00:00 UTC
Maintenance: not required

STDOUT
      end
    end

    context "promotion" do
      it "promotes the specified database" do
        stderr, stdout = execute("pg:promote RONIN --confirm example")
        stderr.should == ""
        stdout.should == <<-STDOUT
Promoting HEROKU_POSTGRESQL_RONIN_URL to DATABASE_URL... done
STDOUT
        api.get_config_vars("example").body["DATABASE_URL"].should == "postgres://ronin_database_url"
      end

      it "fails if no database is specified" do
        stderr, stdout = execute("pg:promote")
        stderr.should == <<-STDERR
 !    Usage: turbot pg:promote DATABASE
 !    Must specify DATABASE to promote.
STDERR
        stdout.should == ""
      end
    end

    context "credential resets" do
      it "resets credentials and promotes to DATABASE_URL if it's the main DB" do
        stub_pg.rotate_credentials
        stderr, stdout = execute("pg:credentials iv --reset")
        stderr.should == ''
        stdout.should == <<-STDOUT
Resetting credentials for HEROKU_POSTGRESQL_IVORY_URL (DATABASE_URL)... done
Promoting HEROKU_POSTGRESQL_IVORY_URL (DATABASE_URL)... done
STDOUT
      end

      it "does not update DATABASE_URL if it's not the main db" do
        stub_pg.rotate_credentials
        api.put_config_vars "example", {
          "DATABASE_URL" => "postgres://to_reset_credentials",
          "HEROKU_POSTGRESQL_RESETME_URL" => "postgres://something_else"
        }
        stderr, stdout = execute("pg:credentials follo --reset")
        stderr.should == ''
        stdout.should_not include("Promoting")
      end

    end

    context "unfollow" do
      it "sends request to unfollow" do
        hpg_client = double('Turbot::Client::TurbotPostgresql')
        Turbot::Client::TurbotPostgresql.should_receive(:new).twice.and_return(hpg_client)
        hpg_client.should_receive(:unfollow)
        hpg_client.should_receive(:get_database).and_return(
          :following => 'postgresql://user:pass@roninhost/database',
          :info => [
            {"name"=>"Plan", "values"=>["Ronin"]},
            {"name"=>"Status", "values"=>["available"]},
            {"name"=>"Data Size", "values"=>["1 MB"]},
            {"name"=>"Tables", "values"=>[1]},
            {"name"=>"PG Version", "values"=>["9.1.4"]},
            {"name"=>"Fork/Follow", "values"=>["Available"]},
            {"name"=>"Created", "values"=>["2011-12-13 00:00 UTC"]},
            {"name"=>"Conn Info", "values"=>["[Deprecated] Please use `turbot pg:credentials HEROKU_POSTGRESQL_RONIN` to view connection info"]},
            {"name"=>"Maintenance", "values"=>["not required"]}
          ]
        )
        stderr, stdout = execute("pg:unfollow HEROKU_POSTGRESQL_FOLLOW_URL --confirm example")
        stderr.should == ""
        stdout.should == <<-STDOUT
 !    HEROKU_POSTGRESQL_FOLLOW_URL will become writable and no longer
 !    follow Database on roninhost:5432/database. This cannot be undone.
Unfollowing HEROKU_POSTGRESQL_FOLLOW_URL... done
STDOUT
      end
    end

  end
end
