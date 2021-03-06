require "turbot/helpers"

module Turbot::Helpers::TurbotPostgresql

  extend self
  extend Turbot::Helpers

  class Attachment
    attr_reader :bot, :name, :config_var, :resource_name, :url, :addon, :plan
    def initialize(raw)
      @raw = raw
      @bot           = raw['bot']['name']
      @name          = raw['name']
      @config_var    = raw['config_var']
      @resource_name = raw['resource']['name']
      @url           = raw['resource']['value']
      @addon, @plan  = raw['resource']['type'].split(':')
    end

    def starter_plan?
      plan =~ /dev|basic/
    end

    def display_name
      config_var + (primary_attachment? ? " (DATABASE_URL)"  : '')
    end

    def primary_attachment!
      @primary_attachment = true
    end

    def primary_attachment?
      @primary_attachment
    end
  end

  def hpg_resolve(identifier, default=nil)
    $stderr.puts " !    #hpg_resolve is deprecated. Please run `turbot plugins:update` to update your plugins."
    $stderr.puts " !    from: #{caller.first}"
    Resolver.new(bot, api).resolve(identifier , default)
  end

  class Resolver
    include Turbot::Helpers
    attr_reader :api, :bot_name
    def initialize(bot_name, api)
      @bot_name = bot_name
      @api = api
    end

    def resolve(identifier, default=nil)
      if identifier =~ /::/
        @bot_name, db_name = identifier.split('::')
      else
        db_name = identifier
      end

      hpg_resolve(db_name, default)
    end

    def all_databases
      hpg_databases
    end

    def database_name_from_url(url)
      vars = bot_config_vars.reject {|key,value| key == 'DATABASE_URL'}
      if var = vars.invert[url]
        var.gsub(/_URL$/, '')
      else
        uri = URI.parse(url)
        "Database on #{uri.host}:#{uri.port || 5432}#{uri.path}"
      end
    end

    def hpg_addon_name
      if ENV['SHOGUN']
        "shogun-#{ENV['SHOGUN']}"
      else
        ENV['TURBOT_POSTGRESQL_ADDON_NAME'] || 'turbot-postgresql'
      end
    end

    private

    def protect_missing_bot
      # in the case where --bot was left out, AND bot::db shorthand was not used, AND no bot autodetect
      unless bot_name
        error("No bot specified.\nRun this command from an bot folder or specify which bot to use with --bot APP.")
      end
    end

    def bot_config_vars
      protect_missing_bot
      @bot_config_vars ||= api.get_config_vars(bot_name).body
    end

    def bot_attachments
      protect_missing_bot
      @bot_attachments ||= api.get_attachments(bot_name).body.map { |raw| Attachment.new(raw) }
    end

    def hpg_databases
      return @hpg_databases if @hpg_databases
      pairs = bot_attachments.select {|att|
          att.addon == hpg_addon_name
        }.map { |att|
          [att.config_var, att]
        }
      @hpg_databases = Hash[ pairs ]

      if find_database_url_real_attachment
        @hpg_databases['DATABASE_URL'] = find_database_url_real_attachment
      end

      return @hpg_databases
    end

    def resource_url(resource)
      api.get_resource(resource).body['value']
    end

    def forget_config!
      @hpg_databases   = nil
      @bot_config_vars = nil
      @bot_attachments = nil
    end

    def find_database_url_real_attachment
      raw_primary_db_url = bot_config_vars['DATABASE_URL']
      return unless raw_primary_db_url

      primary_db_url = raw_primary_db_url.split("?").first
      return unless primary_db_url && !primary_db_url.empty?

      real_config = bot_config_vars.detect {|k,v| k != 'DATABASE_URL' && v == primary_db_url }
      if real_config
        real = hpg_databases[real_config.first]
        real.primary_attachment! if real
        return real
      else
        return nil
      end
    end

    def match_attachments_by_name(name)
       return [] if name.empty?
       return [name] if hpg_databases[name]
       hpg_databases.keys.grep(%r{#{ name }}i)
    end

    def hpg_resolve(name, default=nil)
      name = '' if name.nil?
      name = 'DATABASE_URL' if name == 'DATABASE'

      if hpg_databases.empty?
        error("Your bot has no databases.")
      end

      found_attachment = nil
      candidates = match_attachments_by_name(name)
      if default && name.empty? && bot_config_vars[default]
        found_attachment = hpg_databases[default]
      elsif candidates.size == 1
        found_attachment = hpg_databases[candidates.first]
      end

      if found_attachment.nil?
        error("Unknown database#{': ' + name unless name.empty?}. Valid options are: #{hpg_databases.keys.sort.join(", ")}")
      end

      return found_attachment
    end
  end

  def hpg_translate_fork_and_follow(addon, config)
    $stderr.puts " !    #hpg_translate_fork_and_follow is deprecated. Update your plugins."
    hpg_translate_db_opts_to_urls(addon, config)
  end

  def hpg_translate_db_opts_to_urls(addon, config)
    bot_name = bot rescue nil
    resolver = Resolver.new(bot_name, api)
    if addon =~ /^#{resolver.hpg_addon_name}/
      %w[fork follow rollback].each do |opt|
        if val = config[opt]
          unless val.is_a?(String)
            error("--#{opt} requires a database argument.")
          end

          uri = URI.parse(val) rescue nil
          if uri && uri.scheme && uri.scheme == 'postgres'
            argument_url = uri.to_s
          else
            attachment = resolver.resolve(val)
            if attachment.starter_plan?
              error("#{opt.tr 'f', 'F'} is only available on production databases.")
            end
            argument_url = attachment.url
          end

          config[opt] = argument_url
        end
      end
    end
  end

  private

  def hpg_promote(url)
    api.put_config_vars(bot, "DATABASE_URL" => url)
  end

end
