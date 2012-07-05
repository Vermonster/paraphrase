require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/delegation'
require 'active_model/naming'

module Paraphrase
  class Query
    extend ActiveModel::Naming

    # @!attribute [r] scopes
    #   @return [Array<ScopeMapping>] scopes for query
    #
    # @!attribute [r] source
    #   @return [ActiveRecord::Relation] source to apply scopes to
    cattr_reader :scopes, :source
    @@scopes = []


    # Delegate enumerable methods to results
    delegate :collect, :map, :each, :select, :to_a, :to_ary, :to => :results


    # @!attribute [r] errors
    #   @return [ActiveModel::Errors] errors from determining results
    #
    # @!attribute [r] params
    #   @return [Hash] filters parameters based on keys defined in scopes
    attr_reader :errors, :params


    # Specify the ActiveRecord model to use as the source for queries
    #
    # @param [String, Symbol, ActiveRecord::Base] klass name of the class to
    #   use or the class itself
    def self.paraphrases(klass)
      if !klass.is_a?(Class)
        klass = Object.const_get(klass.to_s.classify)
      end

      @@source = klass.scoped

      Paraphrase.add(klass.name, self)
    end


    # Add a {ScopeMapping} instance to {@@scopes .scopes}
    #
    # @see ScopeMapping#initialize
    def self.scope(name, options)
      if @@scopes.map(&:method_name).include?(name)
        raise DuplicateScopeError, "scope :#{name} has already been added"
      end

      @@scopes << ScopeMapping.new(name, options)
    end


    # Filters out parameters irrelevant to the query
    #
    # @param [Hash] params query parameters
    def initialize(params = {})
      keys = scopes.map(&:param_keys).flatten
      @params = params.dup
      @params.select! { |key, value| keys.include?(key) }
      @params.freeze

      @errors = ActiveModel::Errors.new(self)
    end


    # Loops through {#scopes} and apply scope methods to {#source}. If values
    # are missing for a required key, an empty array is returned.
    #
    # @return [ActiveRecord::Relation, Array]
    def results
      results ||= scopes.inject(source) do |query, scope|
        scope.chain(self, @params, query)
      end

      @results = @errors.any? ? [] : results
    end
  end
end

require 'paraphrase/scope_mapping'
