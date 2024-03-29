require "fileutils"

class Reciper
  class NoTestOutput < RuntimeError
  end

  class NoFileToBeOverriden < RuntimeError
  end

  class NoFileOrMultipleFilesFound < RuntimeError
  end

  module Helpers
    # Copies the file from recipe to ruby_app.
    #
    #  filename - The file to be copied relative to the recipe_path
    #  options - The hash options to configure the copy (default: {}):
    #         :as - The copy name (default: the file name).
    #         :to - The destination dir relative to the ruby_app_path. If the directory doesn't exists, it will be created (default: ruby_app_path root path).
    #
    # Examples
    #
    #   copy_file("a.rb")
    #   copy_file("a.rb", :to => "app/models", :as => "person.rb")
    #
    # Returns nothing.
    def copy_file(filename, options={})
      destination_file_name = options[:as] || filename
      destination_dir = options[:to] || ""

      destination = File.join(destination_dir , destination_file_name)
      global_destination = File.join(@ruby_app_path, destination)

      create_directory_if_not_exists(File.join(@ruby_app_path, destination_dir)) unless options[:to].blank?

      FileUtils.cp(File.join(@recipe_path, filename), global_destination)
    end

    # Run the tests on the ruby app.
    #
    # Examples
    #
    #  run_tests()
    #  # => 2
    #
    # Returns the number of failures
    def run_tests
      result = run_command("bundle exec rspec spec")

      if result[:response] =~ /([\.FE*]+)/
        $1.split("").reject { |char| (char == "." || char == "*") }.size
      else
        puts "Can't get any test output"
        fail NoTestOutput
      end
    end

    # Run a rake task on the ruby app.
    #
    #  task - the desired task
    #
    # Examples
    #
    #  rake_task("db:migrate")
    #  # => { :successful => true, :response => ""}
    #  rake_task("db:migrate")
    #  # => { :successful => false, :response => "Couldn't find the specified DB"}
    #
    # Returns a command execution hash
    def run_rake_task(task)
      run_command("bundle exec rake #{task}")
    end

    # Copies a range of lines from a file on the recipe path to a file on the ruby app path.
    #
    #  from - the file, relative to the recipe path, that contains the file with the lines that will be copied
    #  to - the file, relative to the ruby app path, that contains the file that will receive the files. You can also specify a suffix like *.rb and if it matches only one file, it will insert the lines to it, otherwise it will raise a NoFileOrMultipleFilesFound exception
    #  options - some options related to the line copy (default: {})
    #         :to_line - The line where the content will be inserted (default: raises an exception)
    #         :lines - A range that specifies the lines that will be copied (default: whole file (0..-1))
    #
    # Examples
    #
    #  copy_line_range("a.rb", "app/models/person.rb", :to_line => 42)
    #  copy_line_range("a.rb", "app/models/person.rb", :to_line => 42, :lines => (4..10))
    #  copy_line_range("a.rb", "db/migrate/*create_users.rb", :to_line => 10, :lines => (1..5))
    #
    # Returns nothing.
    def copy_line_range(from, to, options={})
      original_file = filename_from_suffix(to)

      original_content = File.read(original_file)
      original = original_content.split("\n")

      new_content = File.read(File.join(@recipe_path, from)).split("\n")

      range = options[:lines] || (0..-1)

      original.insert(options[:to_line], new_content[range])

      File.open(original_file, "w") do |file|
        file.write(original.flatten.join("\n"))
      end
    end

    # Runs a command using bundle exec on the ruby app path.
    #
    #  command - the command. It will run inside a bundle exec.
    #  rollback_command - the command which rollbacks the command (default: nil)
    #
    # Examples
    #
    #  run_command("ls")
    #  # => { :successful => true, response => "file.rb\n\file2.rb" }
    #  run_command("rails g model user", "rails d model user")
    #  # => { :successful => true, response => "model was generated" }
    #  run_command("cp a.rb b.rb")
    #  # => { :successful => false, response => "file a.rb doesn't exists" }
    #
    # Returns a command execution hash
    def run_command(command)
      response = ""
      successful = ""

      run_on_app_path do
        IO.popen(command) do |io|
          response = io.read
        end

        successful = ($?.exitstatus == 0)
      end

      {
        :successful => successful,
        :response => response
      }
    end

    # Overrides a file of the ruby app with a file from the recipe path.
    #
    #  file - The file that will override relative to the recipe path
    #  file_to_be_overriden - The file that will be overriden
    #
    # Examples
    #
    #  override_file("a.rb", "app/controller/application_controller.rb")
    #
    # Returns nothing
    def override_file(file, file_to_be_overriden)
      run_on_app_path do
        fail NoFileToBeOverriden unless File.exists?(file_to_be_overriden)
      end

      FileUtils.cp(File.join(@recipe_path,file), File.join(@ruby_app_path, file_to_be_overriden))
    end

    private

    def filename_from_suffix(suffix)
      files = Dir.glob(File.join(@ruby_app_path, suffix))
      fail NoFileOrMultipleFilesFound if files.size != 1
      files.first
    end

    def create_directory_if_not_exists(directory)
      FileUtils.mkdir_p(directory) unless File.directory?(directory)
    end

    def run_on_app_path
      Dir.chdir(@ruby_app_path) do
        yield
      end
    end

    def remove_file(file)
      run_on_app_path do
        FileUtils.rm(file)
      end
    end

    def write_content_to_file(filename, content)
      File.open(filename, "w") do |file|
        file.write(content)
      end
    end
  end
end