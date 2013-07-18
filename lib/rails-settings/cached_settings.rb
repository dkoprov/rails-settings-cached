module RailsSettings
  class CachedSettings < Settings
    after_update :rewrite_cache
    after_create :rewrite_cache
    def rewrite_cache
      Rails.cache.write("settings:#{self.var}, namespace:#{self.namespace}", self.value)
    end

    after_destroy { |record| Rails.cache.delete("settings:#{record.var}, namespace:#{record.namespace}") }

    def self.[](var_args)
      raise Settings::NamespaceNotProvided unless var_args.is_a?(Hash)
      var_namespace = var_args.keys.first
      var_name = var_args.values.first
      obj = Rails.cache.fetch("settings:#{var_name}, namespace:#{var_namespace}") {
        super(var_namespace => var_name)
      }
      obj || @@defaults[var_name]
    end

    def self.save_default(key_namespace,key,value)
      key_namespace = key_namespace.to_s
      key = key.to_s
      if self[key_namespace => key] == nil
        self[key_namespace => key] = value
      end
    end
  end
end
