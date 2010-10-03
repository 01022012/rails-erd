require File.expand_path("../test_helper", File.dirname(__FILE__))

class DiagramTest < ActiveSupport::TestCase
  def setup
    load "rails_erd/diagram.rb"
  end
  
  def teardown
    RailsERD.send :remove_const, :Diagram
  end
  
  def retrieve_relationships(options = {})
    klass = Class.new(Diagram)
    [].tap do |relationships|
      klass.class_eval do
        define_method :process_relationship do |relationship|
          relationships << relationship
        end
      end
      klass.create(options)
    end
  end

  def retrieve_entities(options = {})
    klass = Class.new(Diagram)
    [].tap do |entities|
      klass.class_eval do
        define_method :process_entity do |entity, attributes|
          entities << entity
        end
      end
      klass.create(options)
    end
  end
  
  def retrieve_attribute_lists(options = {})
    klass = Class.new(Diagram)
    {}.tap do |attribute_lists|
      klass.class_eval do
        define_method :process_entity do |entity, attributes|
          attribute_lists[entity.model] = attributes
        end
      end
      klass.create(options)
    end
  end
  
  # Diagram ==================================================================
  test "create class method should return result of save" do
    create_simple_domain
    subclass = Class.new(Diagram) do
      def save
        "foobar"
      end
    end
    assert_equal "foobar", subclass.create
  end

  test "create should return result of save" do
    create_simple_domain
    diagram = Class.new(Diagram) do
      def save
        "foobar"
      end
    end.new(Domain.generate)
    assert_equal "foobar", diagram.create
  end
  
  test "domain sould return given domain" do
    domain = Object.new
    assert_same domain, Class.new(Diagram).new(domain).domain
  end

  # Diagram abstractness =====================================================
  test "create should succeed silently if called on abstract class" do
    create_simple_domain
    assert_nothing_raised do
      Diagram.create
    end
  end

  test "create should succeed if called on class that implements process_entity and process_relationship" do
    create_simple_domain
    assert_nothing_raised do
      Class.new(Diagram) do
        def process_entity(*args)
        end
        def process_relationship(*args)
        end
      end.create
    end
  end
  
  # Entity filtering =========================================================
  test "generate should yield entities" do
    create_model "Foo"
    assert_equal [Foo], retrieve_entities.map(&:model)
  end

  test "generate should filter disconnected entities if disconnected is false" do
    create_model "Book", :author => :references do
      belongs_to :author
    end
    create_model "Author"
    create_model "Table", :type => :string
    assert_equal [Author, Book], retrieve_entities(:disconnected => false).map(&:model)
  end

  test "generate should yield disconnected entities if disconnected is true" do
    create_model "Foo", :type => :string
    assert_equal [Foo], retrieve_entities(:disconnected => true).map(&:model)
  end

  test "generate should filter descendant entities" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    assert_equal [Foo], retrieve_entities.map(&:model)
  end
  
  test "generate should yield descended entities with distinct tables" do
    create_model "Foo"
    Object.const_set :SpecialFoo, Class.new(Foo)
    SpecialFoo.class_eval do
      set_table_name "special_foo"
    end
    create_table "special_foo", {}, true
    assert_equal [Foo, SpecialFoo], retrieve_entities.map(&:model)
  end
  
  # Relationship filtering ===================================================
  test "generate should yield relationships" do
    create_simple_domain
    assert_equal 1, retrieve_relationships.length
  end

  test "generate should yield indirect relationships if indirect is true" do
    create_model "Foo" do
      has_many :bazs
      has_many :bars
    end
    create_model "Bar", :foo => :references do
      belongs_to :foo
      has_many :bazs, :through => :foo
    end
    create_model "Baz", :foo => :references do
      belongs_to :foo
    end
    assert_equal [false, false, true], retrieve_relationships(:indirect => true).map(&:indirect?)
  end
  
  test "generate should filter indirect relationships if indirect is false" do
    create_model "Foo" do
      has_many :bazs
      has_many :bars
    end
    create_model "Bar", :foo => :references do
      belongs_to :foo
      has_many :bazs, :through => :foo
    end
    create_model "Baz", :foo => :references do
      belongs_to :foo
    end
    assert_equal [false, false], retrieve_relationships(:indirect => false).map(&:indirect?)
  end

  test "generate should filter relationships from descendant entities" do
    create_model "Foo", :bar => :references
    create_model "Bar", :type => :string
    Object.const_set :SpecialBar, Class.new(Bar)
    SpecialBar.class_eval do
      has_many :foos
    end
    assert_equal [], retrieve_relationships
  end
  
  test "generate should filter relationships to descendant entities" do
    create_model "Foo", :type => :string, :bar => :references
    Object.const_set :SpecialFoo, Class.new(Foo)
    create_model "Bar" do
      has_many :special_foos
    end
    assert_equal [], retrieve_relationships
  end

  # Attribute filtering ======================================================
  test "generate should yield regular attributes by default" do
    create_model "Book", :title => :string, :created_at => :datetime, :author => :references do
      belongs_to :author
    end
    create_model "Author"
    assert_equal %w{title}, retrieve_attribute_lists[Book].map(&:name)
  end

  test "generate should yield primary key attributes if included" do
    create_model "Book", :title => :string
    create_model "Page", :book => :references do
      belongs_to :book
    end
    assert_equal %w{id}, retrieve_attribute_lists(:attributes => [:primary_keys])[Book].map(&:name)
  end

  test "generate should yield foreign key attributes if included" do
    create_model "Book", :author => :references do
      belongs_to :author
    end
    create_model "Author"
    assert_equal %w{author_id}, retrieve_attribute_lists(:attributes => [:foreign_keys])[Book].map(&:name)
  end

  test "generate should yield timestamp attributes if included" do
    create_model "Book", :created_at => :datetime, :created_on => :date, :updated_at => :datetime, :updated_on => :date
    create_model "Page", :book => :references do
      belongs_to :book
    end
    assert_equal %w{created_at created_on updated_at updated_on},
      retrieve_attribute_lists(:attributes => [:timestamps])[Book].map(&:name)
  end

  test "generate should yield combinations of attributes if included" do
    create_model "Book", :created_at => :datetime, :title => :string, :author => :references do
      belongs_to :author
    end
    create_model "Author"
    assert_equal %w{created_at title},
      retrieve_attribute_lists(:attributes => [:regular, :timestamps])[Book].map(&:name)
  end
end
