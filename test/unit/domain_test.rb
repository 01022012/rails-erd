require File.expand_path("../test_helper", File.dirname(__FILE__))

class DomainTest < ActiveSupport::TestCase
  # Domain ===================================================================
  test "generate should return domain" do
    assert_kind_of Domain, Domain.generate
  end
  
  test "name should return rails application name" do
    begin
      Object::Quux = Module.new
      Object::Quux::Application = Class.new
      Object::Rails = Struct.new(:application).new(Object::Quux::Application.new)
      assert_equal "Quux", Domain.generate.name
    ensure
      Object::Quux.send :remove_const, :Application
      Object.send :remove_const, :Quux
      Object.send :remove_const, :Rails
    end
  end
  
  test "name should return nil outside rails" do
    assert_nil Domain.generate.name
  end
  
  test "inspect should display relationships" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_match %r{#<RailsERD::Domain:.* \{Bar => Foo\}>}, Domain.generate.inspect
  end
  
  # Entity processing ========================================================
  test "entity_for should return associated entity for given model" do
    create_model "Foo"
    assert_equal Foo, Domain.generate.entity_for(Foo).model
  end
  
  test "entities should return domain entities" do
    create_models "Foo", "Bar"
    assert_equal [Entity] * 2, Domain.generate.entities.collect(&:class)
  end
  
  test "entities should return all domain entities sorted by name" do
    create_models "Foo", "Bar", "Baz", "Qux"
    assert_equal [Bar, Baz, Foo, Qux], Domain.generate.entities.collect(&:model)
  end
  
  # Relationship processing ==================================================
  test "relationships should return empty array for empty domain" do
    assert_equal [], Domain.generate.relationships
  end
  
  test "relationships should return relationships in domain model" do
    create_models "Baz", "Qux"
    create_model "Foo", :bar => :references, :qux => :references do
      belongs_to :bar
      belongs_to :qux
    end
    create_model "Bar", :baz => :references do
      belongs_to :baz
    end
    assert_equal [Relationship] * 3, Domain.generate.relationships.collect(&:class)
  end
  
  test "relationships should count mutual relationship as one" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [Relationship], Domain.generate.relationships.collect(&:class)
  end
  
  test "relationships should count relationship between same models with distinct foreign key seperately" do
    create_model "Foo", :bar => :references, :special_bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos, :foreign_key => :special_bar_id
    end
    assert_equal [Relationship] * 2, Domain.generate.relationships.collect(&:class)
  end
  
  # Erroneous associations ===================================================
  test "relationships should omit bad has_many associations" do
    create_model "Foo" do
      has_many :flabs
    end
    assert_equal [], Domain.generate(:warn => false).relationships
  end
  
  test "relationships should omit bad has_many through association" do
    create_model "Foo" do
      has_many :flabs, :through => :bars
    end
    assert_equal [], Domain.generate(:warn => false).relationships
  end
  
  test "relationships should omit association to model outside domain" do
    create_model "Foo" do
      has_many :bars
    end
    create_model "Bar", :foo => :references
    assert_equal [], Domain.new([Foo], :warn => false).relationships
  end

  test "relationships should output a warning when a bad association is encountered" do
    create_model "Foo" do
      has_many :flabs
    end
    output = collect_stdout do
      Domain.generate.relationships
    end
    assert_match /Ignoring invalid association :flabs on Foo/, output
  end

  test "relationships should output a warning when an association to model outside domain is encountered" do
    create_model "Foo" do
      has_many :bars
    end
    create_model "Bar", :foo => :references
    output = collect_stdout do
      Domain.new([Foo]).relationships
    end
    assert_match /model Bar exists, but is not included in domain/, output
  end

  test "relationships should not warn when a bad association is encountered if warnings are disabled" do
    create_model "Foo" do
      has_many :flabs
    end
    output = collect_stdout do
      Domain.generate(:warn => false).relationships
    end
    assert_equal "", output
  end
end
