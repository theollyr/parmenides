module Parmenides
  class Entity

    attr_reader :uri

    def self.has_property property

      # property = property.to_s.split( "_" ).map( &:capitalize ).join
      # property[0] = property[0].downcase

      self.class_eval <<-EOC

        def #{property}
          @#{property} ||= []
        end

      EOC

    end

    def initialize uri, **kwargs
      @uri = uri
    end

    def == oth
      self.uri == oth.uri
    end

    def inspect
      "#<%s:%d URI:%s>" % [ self.class.to_s, self.object_id, self.uri.to_s ]
    end

  end
end