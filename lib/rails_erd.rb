require "active_support/ordered_options"
require "rails_erd/railtie" if defined? Rails

# Rails ERD provides several options that allow you to customise the
# generation of the diagram and the domain model itself. Currently, the
# following options are supported:
#
# exclude_foreign_keys:: Excludes foreign key columns from attribute lists.
#                        Defaults to +true+.
# exclude_primary_keys:: Excludes primary key columns from attribute lists.
#                        Defaults to +true+.
# exclude_timestamps:: Excludes timestamp columns (<tt>created_at/on</tt> and
#                      <tt>updated_at/on</tt>) from attribute lists. Defaults
#                      to +true+.
# exclude_unconnected:: Excludes entities that are not connected from the diagram.
#                       Defaults to +true+.
# orientation:: The direction of the hierarchy of entities. Either +:horizontal+
#               or +:vertical+. Defaults to +:horizontal+. The orientation of the
#               PDF that is generated greatly depends on the amount of hierarchy
#               in your models.
# suppress_warnings:: When set to +true+, no warnings are printed to the
#                     command line while processing the domain model. Defaults
#                     to +false+.
# type:: The file type of the generated diagram. Defaults to +:pdf+, which
#        is the recommended format. Other formats may render significantly
#        worse than a PDF file.
module RailsERD
  class << self
    # Access to default options. Any instance of RailsERD::Domain and
    # RailsERD::Diagram will use these options unless overridden.
    attr_accessor :options
  end

  self.options = ActiveSupport::OrderedOptions[
    :exclude_foreign_keys, true,
    :exclude_primary_keys, true,
    :exclude_timestamps, true,
    :exclude_unconnected, true,
    :orientation, :horizontal,
    :suppress_warnings, false,
    :type, :pdf
  ]
end
