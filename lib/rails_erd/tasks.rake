def say(message)
  puts message unless Rake.application.options.silent
end

namespace :erd do
  task :options do
    (RailsERD.options.keys.map(&:to_s) & ENV.keys).each do |option|
      RailsERD.options[option.to_sym] = case ENV[option]
      when "true" then true
      when "false" then false
      else ENV[option].to_sym
      end
    end
  end
  
  task :load_models do
    say "Loading Active Record models..."

    Rake::Task[:environment].invoke
    Rails.application.config.paths.app.models.paths.each do |model_path|
      Dir["#{model_path}/**/*.rb"].sort.each do |file|
        require_dependency file
      end
    end
  end
  
  task :generate => [:options, :load_models] do
    say "Generating Entity-Relationship Diagram..."

    require "rails_erd/diagram/graphviz"
    file = RailsERD::Diagram::Graphviz.create

    say "Done! Saved diagram to #{file}."
  end
end

desc "Generate an Entity-Relationship Diagram based on your models"
task :erd => "erd:generate"
