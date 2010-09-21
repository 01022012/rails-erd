require "rails_erd/relationship/cardinality"

module RailsERD
  # Describes a relationship between two entities. A relationship is detected
  # based on Active Record associations. One relationship may represent more
  # than one association, however. Associations that share the same foreign
  # key are grouped together.
  class Relationship
    N = Cardinality::N
    
    class << self
      def from_associations(domain, associations) # @private :nodoc:
        assoc_groups = associations.group_by { |assoc| association_identity(assoc) }
        assoc_groups.collect { |_, assoc_group| Relationship.new(domain, assoc_group.to_a) }
      end
      
      private
      
      def association_identity(assoc)
        identifier = assoc.options[:join_table] || assoc.primary_key_name.to_s
        Set[identifier, assoc.active_record, assoc.klass]
      end
    end

    # The domain in which this relationship is defined.
    attr_reader :domain

    # The source entity. It corresponds to the model that has defined a
    # +has_one+ or +has_many+ association with the other model.
    attr_reader :source
    
    # The destination entity. It corresponds to the model that has defined
    # a +belongs_to+ association with the other model.
    attr_reader :destination
  
    def initialize(domain, associations) # @private :nodoc:
      @domain = domain
      @reverse_associations, @forward_associations = *associations.partition(&:belongs_to?)
    
      assoc = @forward_associations.first || @reverse_associations.first
      @source, @destination = @domain.entity_for(assoc.active_record), @domain.entity_for(assoc.klass)
      @source, @destination = @destination, @source if assoc.belongs_to?
    end
    
    # Returns all Active Record association objects that describe this
    # relationship.
    def associations
      @forward_associations + @reverse_associations
    end
    
    # Returns the cardinality of this relationship.
    def cardinality
      @forward_associations.collect do |assoc|
        l_min = 0
        l_max = assoc.macro == :has_and_belongs_to_many ? N : 1
        r_min = 0
        r_max = assoc.macro == :has_one ? 1 : N
        
        Cardinality.new(l_min..l_max, r_min..r_max)
      end.max or Cardinality.new(1, 0..N) # TODO, flawed logic
    end
    
    # Indicates if a relationship is indirect, that is, if it is defined
    # through other relationships. Indirect relationships are created in
    # Rails with <tt>has_many :through</tt> or <tt>has_one :through</tt>
    # association macros.
    def indirect?
      !@forward_associations.empty? and @forward_associations.all?(&:through_reflection)
    end
    
    # Indicates whether or not the relationship is defined by two inverse
    # associations (e.g. a +has_many+ and a corresponding +belongs_to+
    # association).
    def mutual?
      @forward_associations.any? and @reverse_associations.any?
    end
    
    # Indicates whether or not this relationship connects an entity with itself.
    def recursive?
      @source == @destination
    end
    
    # The strength of a relationship is equal to the number of associations
    # that describe it.
    def strength
      associations.size
    end

    def inspect # @private :nodoc:
      "#<#{self.class}:0x%.14x @source=#{source} @destination=#{destination}>" % (object_id << 1)
    end
  
    def <=>(other) # @private :nodoc:
      (source.name <=> other.source.name).nonzero? or (destination.name <=> other.destination.name)
    end
  end
end
