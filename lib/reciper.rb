require "active_support"
require "active_support/core_ext/string"

class Reciper
  require "reciper/helpers"
  include Reciper::Helpers

  attr_reader :name, :recipe_path, :ruby_app_path

  # Initialize the recipe with the paths. It will clone the ruby_app_template_path to a path that we will run the migration.
  #
  # name - the recipe name
  # recipe_path - the recipe path (absolute or relative to the current path)
  # ruby_app_template_path - the ruby app template path (it will be cloned and it will run the migrations on this copy)
  #
  # Examples
  #
  #   Recipe.new("My freaking awesome recipe", "~/Code/recipe", "~/Code/rails_app/path")
  #
  # Returns a recipe instance with all paths configured
  def initialize(name, recipe_path, ruby_app_template_path)
    @name = name
    @recipe_path = recipe_path
    @ruby_app_path = File.join(".", "tmp", name.parameterize("_"))

    if File.directory?(@ruby_app_path)
      FileUtils.rm_rf(@ruby_app_path)
    end

    FileUtils.mkdir_p("tmp")

    FileUtils.cp_r(ruby_app_template_path, @ruby_app_path)
  end

  # Executes a recipe inside the block.
  #
  # Examples
  #
  #   recipe.execute do
  #     run_rake_task("db:migrate")
  #     copy_file("file.rb", :as => "user.rb")
  #   end
  #
  # Returns nothing.
  def execute(&block)
    if block_given?
      instance_eval(&block)
    end
  end
end