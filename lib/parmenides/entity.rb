module Parmenides
  class Entity
    attr_reader :uri

    def self.has_property(property)
      class_eval <<-EOC
        def #{property}
          @#{property} ||= []
        end
      EOC
    end

    def initialize(uri, **_kwargs)
      @uri = uri
    end

    def ==(other)
      uri == other.uri
    end

    def inspect
      "#<%s:%d URI:%s>" % [self.class.to_s, object_id, uri.to_s]
    end
  end
end
