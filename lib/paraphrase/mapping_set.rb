require 'paraphrase/scope_key'

module Paraphrase
  class MappingSet
    attr_reader :params

    class << self
      attr_reader :source, :scope_keys
    end

    def self.paraphrases(source_name)
      @source = Object.const_get(source_name)
    rescue NameError
      raise SourceMissingError, "source #{source} is not defined"
    end

    def self.key(options)
      @scope_keys ||=[]

      scope_key = ScopeKey.new(options)
      @scope_keys << scope_key

      attr_reader scope_key.name
    end

    def initialize(params = {})
      @params = keys.inject({}) do |hash, key|
        attribute = key.name
        value = params[attribute]

        if !value.nil? && !value.empty?
          instance_variable_set("@#{attribute}", value)
          hash[attribute] = value
        end

        hash
      end
    end

    def results
      @results ||= keys.inject(self.class.source) do |result, key|
        input = send(key.name)
        input ? result.send(key.scope, input) : result
      end
    end

    def keys
      self.class.scope_keys
    end
  end
end
