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
      Dir.chdir(@ruby_app_path) do
        response = `rspec spec`

        if response =~ /([.FE]+)/
          $1.split("").reject { |char| char == "." }.size
        else
          puts "Can't get any test output"
          fail NoTestOutput
        end
      end
    end

    def run_rake_task(task)
      Dir.chdir(@ruby_app_path) do
        spawn("rake #{task}", :err=> "/dev/null", :out => "/dev/null")

        Process.wait
      end

      $?.exitstatus == 0
    end
  end

end