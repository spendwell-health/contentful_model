module ContentfulModel
  class Base < Contentful::Entry
    include ContentfulModel::ChainableQueries

    def initialize(*args)
      super
      self.class.coercions ||= {}
    end

    #use method_missing to call fields on the model
    def method_missing(method)
      result = fields[:"#{method}"]
      if result.nil?
        raise NoMethodError, "No method or attribute #{method} for #{self}"
      else
        if self.class.coercions[method].nil?
          return result
        else
          return self.class::COERCIONS[self.class.coercions[method]].call(result)
        end
      end
    end

    class << self
      attr_accessor :content_type_id, :coercions

      def descendents
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def add_entry_mapping
        unless ContentfulModel.configuration.entry_mapping.has_key?(@content_type_id)
          ContentfulModel.configuration.entry_mapping[@content_type_id] = Object.const_get(self.to_s.to_sym)
        end
      end

      def client
        self.add_entry_mapping
        @@client ||= Contentful::Client.new(ContentfulModel.configuration.to_hash)
      end

      def content_type
        client.content_type(@content_type_id)
      end

      def coerce_field(coercions_hash)
        self.coercions = coercions_hash
      end

      def find(id)
        @query ||= ContentfulModel::Query.new(self)
        @query << {'sys.id' => id}
        @query.execute.first
      end

    end






  end
end