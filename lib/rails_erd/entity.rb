module RailsERD
  # Entities represent your Active Record models. Entities may be connected
  # to other entities.
  class Entity
    # The domain in which this entity resides.
    attr_reader :domain
    
    # The Active Record model that this entity corresponds to.
    attr_reader :model

    def initialize(domain, model) # @private :nodoc:
      @domain, @model = domain, model
    end
    
    # Returns an array of attributes for this entity.
    def attributes
      @attributes ||= Attribute.from_model @domain, @model
    end
    
    # Returns an array of all relationships that this entity has with other
    # entities in the domain model.
    def relationships
      @domain.relationships_for(@model)
    end
    
    # Returns +true+ if this entity has any relationships with other models,
    # +false+ otherwise.
    def connected?
      relationships.any?
    end
  
    # Returns the name of this entity, which is the class name of the
    # corresponding model.
    def name
      model.name
    end
  
    def inspect # @private :nodoc:
      "#<#{self.class}:0x%.14x @model=#{name}>" % (object_id << 1)
    end
    
    def to_s # @private :nodoc:
      name
    end
  
    def <=>(other) # @private :nodoc:
      self.name <=> other.name
    end
  end
end
