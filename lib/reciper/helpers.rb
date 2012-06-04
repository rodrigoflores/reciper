require "fileutils"

module Reciper
  class NoTestOutput < RuntimeError
  end

  class NoFileToBeOverriden < RuntimeError
  end

  class NoFileOrMultipleFilesFound < RuntimeError
  end

  module Helpers
    def copy_file(filename, options={})
      destination_file_name = options[:as] || filename
      destination_dir = options[:to] || ""

      destination = File.join(destination_dir , destination_file_name)
      global_destination = File.join(@ruby_app_path, destination)

      create_directory_if_not_exists(File.join(@ruby_app_path, destination_dir))

      FileUtils.cp(File.join(@recipe_path, filename), global_destination)

      @operations << [:copy_file, { :destination => destination }]
    end

    def run_tests(options={})
      result = run_command("bundle exec rspec spec")

      if result[:response] =~ /([\.FE*]+)/
        $1.split("").reject { |char| (char == "." || char == "*") }.size
      else
        puts "Can't get any test output"
        fail NoTestOutput
      end
    end

    def run_rake_task(task)
      run_command("bundle exec rake #{task}")
    end

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

      @operations << [:copy_line_range, { :original_content => original_content, :original_file => original_file }]
    end

    def rollback
      @operations.reverse.each do |operation|
        operation_name, arguments = operation

        if operation_name == :copy_file
          remove_file(arguments[:destination])
        elsif operation_name == :copy_range
          File.open(arguments[:original_file], "w") do |file|
            file.write(arguments[:original_content])
          end
        elsif operation_name == :run_command
          if arguments[:rollback_command]
            run_command(arguments[:rollback_command])
          end
        elsif operation_name == :override_file
          FileUtils.cp(arguments[:tmp_file], File.join(@ruby_app_path, arguments[:overriden_file]))
        end
      end
    end

    def run_command(command, rollback_command=nil)
      response = ""
      successful = ""

      run_on_app_path do
        IO.popen(command) do |io|
          response = io.read
        end

        successful = ($?.exitstatus == 0)
      end

      @operations << [:run_command, { :rollback_command => rollback_command }]

      {
        :successful => successful,
        :response => response
      }
    end

    def override_file(file, file_to_be_overriden)
      run_on_app_path do
        fail NoFileToBeOverriden unless File.exists?(file_to_be_overriden)

        FileUtils.mkdir_p("/tmp/reciper")
        filename = File.basename(file_to_be_overriden)
        tmp_file = "/tmp/reciper/#{filename}"

        FileUtils.cp(file_to_be_overriden, tmp_file)

        @operations << [:override_file, { :tmp_file => tmp_file, :overriden_file => file_to_be_overriden }]
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
  end
end