module CHF
  # A central place for environmental/infrastructure type configuration.
  # We still have lots of this in other places too that predates this, but
  # this is our attempt to centralize it.
  #
  # Values will be taken from, in priority order:
  #   * ENV if present -- uppercased. ENV['FOO_BAR'] for key 'foo_bar'. Or can set custom ENV key per config key.
  #   * else the config/local_env.yml file if present and has key. This file
  #     is supplied by ansible with level/role-specific values, or might
  #     be created by hand in dev if convenient.
  #   * defaults configured in this class.
  #
  # Lookup with:
  #
  #     Chf::Env.lookup("some_key")
  #
  # You can only look up keys defined like so:
  #
  #     define_key(:some_key)
  #     define_key(:some_key, env: false) # disable ENV lookup
  #     define_key(:some_key, env: "SPECIFY_ENV_VAR") # non-defualt ENV lookup key
  #     define_key(:some_key, default: "foo")
  #     define_key(:some_key, default: -> { proc_that_provides_value} ) # will only be called once and cached
  #
  # Keys are defined at the bottom of this file, to make sure all methods are
  # defined first! (Extract to another file? Want to make sure they get defined
  # right away so can be used at any point in boot process)
  #
  # This implementation is a bit hacky, but I think the public API is hopefully
  # good and stable.
  class Env


    def initialize
      @key_definitions = {}
      @local_env_path = Rails.root.join('config', 'local_env.yml')
    end

    def self.define_key(*args)
      instance.define_key(*args)
    end

    def self.lookup(*args)
      instance.lookup(*args)
    end

    def define_key(name, env_key: nil, default: nil)
      @key_definitions[name.to_sym] = {
        name: name.to_s,
        env_key: env_key,
        default: default
      }
    end

    def lookup(name)
      defn = @key_definitions[name.to_sym]
      raise ArgumentError.new("No env key defined for: #{name}") unless defn

      system_env_lookup(defn) || local_env_file_lookup(defn) || default_lookup(defn)
    end

    protected

    def system_env_lookup(defn)
      return nil if defn[:env_key] == false

      ENV[defn[:env_key] || defn[:name].upcase]
    end

    def local_env_file_lookup(defn)
      @local_env_loaded ||= load_yaml_file
      @local_env_loaded[defn[:name]]
    end

    def load_yaml_file
      return {} unless File.exist?(@local_env_path)
      YAML.load(File.open(@local_env_path))
    end

    # default lookup is cached, this kind of env config should be immutable
    def default_lookup(defn)
      if defn.has_key?(:cached_default)
        defn[:cached_default]
      else
        defn[:cached_default] = if defn[:default].respond_to?(:call)
                                  # allow a proc that gets executed on demand
                                  defn[:default].call
                                else
                                  defn[:default]
                                end
      end
    end

    public

    @instance = self.new
    def self.instance
      @instance
    end

    ######
    #
    #  Define keys here
    #
    ######

    self.define_key :public_riiif_url
    self.define_key :app_role
    self.define_key :service_level

    # Ideally these would be in local_env.yml independently,
    # but for now we calculate based on app_role value, but do it here
    # so we have one place to change.
    # Can still override with ENV or local_env.yml locally, nice!
    self.define_key :serve_riiif_paths, default: -> {
      lookup(:app_role).blank? || lookup(:app_role) == "riiif"
    }
    self.define_key :serve_app_paths, default: -> {
      lookup(:app_role).blank? || lookup(:app_role) == "app"
    }

  end
end
