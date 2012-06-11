require "active_support"
require "active_support/core_ext/string"

class Reciper
  require "reciper/helpers"

  attr_reader :name, :recipe_path, :ruby_app_path

  def initialize(name, recipe_path, ruby_app_template_path)
    @name = name
    @recipe_path = recipe_path
    @ruby_app_path = File.join(".", "tmp", name.parameterize("_"))

    if File.directory?(@ruby_app_path)
      FileUtils.rm_rf(@ruby_app_path)
    end

    FileUtils.cp_r(ruby_app_template_path, @ruby_app_path)
  end

  def execute(&block)
    if block_given?
      instance_eval(&block)
    end
  end
end