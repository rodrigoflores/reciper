require "fileutils"

module Reciper
  class NoTestOutput < RuntimeError
  end

  module Helpers
    def copy_file(filename, options={})
      destination_dir = @ruby_app_path + "/" + (options[:to] || "")

      unless File.directory?(destination_dir)
        FileUtils.mkdir_p(destination_dir)
      end

      FileUtils.cp(@recipe_path + "/" + filename, destination_dir)
    end

    def run_tests(options={})
      current_dir = Dir.pwd
      Dir.chdir(@ruby_app_path)

      response = `rspec spec`

      if response =~ /([.FE]+)/
        failures = $1.split("").reject { |char| char == "." }.size
      else
        puts "Can't get any test output"
        fail NoTestOutput
      end

      Dir.chdir current_dir

      failures
    end
  end
end