module RailsSettings
  class Settings < ActiveRecord::Base

    self.table_name = 'settings'

    class SettingNotFound < StandardError; end
    class NamespaceNotProvided < StandardError; end

    cattr_accessor :defaults
    @@defaults = {}.with_indifferent_access

    # Support old plugin
    if defined?(SettingsDefaults::DEFAULTS)
      @@defaults = SettingsDefaults::DEFAULTS.with_indifferent_access
    end

    class << self
      # for ActiveRecord 4 compatibility (method `where` is delegated to `all`)
      query_results_method_name = ActiveRecord::VERSION::MAJOR >= 4 ? :all : :scoped
      alias_method :original_all, query_results_method_name

      delegate :pluck, :update_all, :where, :destroy_all, to: :original_all, allow_nil: true
    end

    #get or set a variable with the variable as the called method
    def self.method_missing(method, *args)
      method_name = method.to_s
      super(method, *args)

    rescue NoMethodError
      #set a value for a variable
      if method_name =~ /=$/
        var_name = method_name.gsub('=', '')
        value = args.first
        self[var_name] = value

      #retrieve a value
      else
        var_namespace = args.first
        raise NamespaceNotProvided if var_namespace.nil?
        self[var_namespace.to_s => method_name]
      end
    end

    #destroy the specified settings record
    def self.destroy(var_namespace, var_name)
      var_namespace = var_namespace.to_s
      var_name = var_name.to_s
      if self[var_namespace => var_name]
        object(var_namespace, var_name).destroy
        true
      else
        raise SettingNotFound, "Setting variable \"#{var_name}\" with namespace \"#{var_namespace}\" is not found"
      end
    end

    #retrieve all settings as a hash (optionally with a given namespace)
    def self.all(var_namespace=nil)
      vars = thing_scoped.select('var, value')
      vars = vars.where(namespace: var_namespace.to_s) if var_namespace.present?

      result = {}
      vars.each do |record|
        result[record.var] = record.value
      end
      result.with_indifferent_access
    end

    #get a setting value by [] notation
    def self.[](var_args)
      raise NamespaceNotProvided unless var_args.is_a?(Hash)
      var_name = var_args.values.first
      var_namespace = var_args.keys.first
      if var = object(var_namespace, var_name)
        var.value
      elsif @@defaults[var_name]
        @@defaults[var_name]
      else
        nil
      end
    end

    #set a setting value by [] notation
    def self.[]=(var_hash, value)
      raise NamespaceNotProvided unless var_hash.is_a?(Hash)
      var_namespace = var_hash.keys.first.to_s
      var_name = var_hash.values.first.to_s

      record = object(var_namespace, var_name) || thing_scoped.new{|ts| ts.namespace=var_namespace; ts.var=var_name}
      record.value = value
      record.save!

      value
    end

    def self.merge!(var_namespace, var_name, hash_value)
      raise ArgumentError unless hash_value.is_a?(Hash)

      old_value = self[var_namespace => var_name] || {}
      raise TypeError, "Existing value is not a hash, can't merge!" unless old_value.is_a?(Hash)

      new_value = old_value.merge(hash_value)
      self[var_namespace => var_name] = new_value if new_value != old_value

      new_value
    end

    def self.object(var_namespace, var_name)
      thing_scoped.where(:namespace => var_namespace.to_s, :var => var_name.to_s).first
    end

    #get the value field, YAML decoded
    def value
      YAML::load(self[:value])
    end

    #set the value field, YAML encoded
    def value=(new_value)
      self[:value] = new_value.to_yaml
    end

    def self.thing_scoped
      where(thing_type: nil, thing_id: nil)
    end
  end
end
