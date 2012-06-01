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

      if destination_dir == ""
        destination = destination_file_name
      else
        destination = File.join(destination_dir, destination_file_name)
      end

      global_destination = File.join(@ruby_app_path, destination)

      create_directory_if_not_exists(File.join(@ruby_app_path, destination_dir))

      FileUtils.cp(File.join(@recipe_path, filename), global_destination)

      @operations << [:copy, { :destination => destination }]
    end

    def run_tests(options={})
      Dir.chdir(@ruby_app_path) do
        response = `bundle exec rspec spec`

        if response =~ /([\.FE*]+)/
          $1.split("").reject { |char| (char == "." || char == "*") }.size
        else
          puts "Can't get any test output"
          fail NoTestOutput
        end
      end
    end

    def run_rake_task(task)
      Dir.chdir(@ruby_app_path) do
        spawn("bundle exec rake #{task}", :out => "/dev/null", :err => "/dev/null")

        Process.wait
      end

      $?.exitstatus == 0
    end

    def copy_line_range(from, to, options={})
      if options[:from_lines]
        from_lines = Range.new(options[:from_lines].first - 1, options[:from_lines].last - 1)
      else
        from_lines = (0..-1)
      end

      from_file_lines = File.open(@recipe_path + "/" + from, "r").readlines

      to_files = Dir[@ruby_app_path + "/" + to]
      to_file = ""

      if to_files.size == 1
        to_file = to_files.first
      else
        raise NoFileOrMultipleFilesFound, "No file or multiple files found"
      end

      output_lines = File.read(to_file).split("\n")
      original_output = output_lines.dup

      to_file_output = File.open(to_file, "w")

      to_output = output_lines.insert(options[:to_line] - 1, from_file_lines.map(&:chomp).slice(from_lines)).flatten!.join("\n")

      to_file_output.write(to_output)

      to_file_output.close

      @operations << [:copy_range, to_file[(@ruby_app_path.size+1)..-1], original_output.join("\n")]
    end

    def rollback
      @operations.reverse.each do |operation|
        if operation[0] == :copy
          FileUtils.rm(@ruby_app_path + "/" + operation[1])
        elsif operation[0] == :copy_range
          File.open(@ruby_app_path + "/" + operation[1], "w") { |file| file.write(operation[2]) }
        elsif operation[0] == :run_command
          spawn(operation[1]) if operation[1]

          Process.wait
        elsif operation[0] == :override_file
          FileUtils.cp(operation[1], @ruby_app_path + "/" + operation[2])
        end
      end
    end

    def run_command(command, rollback_command=nil)
      Dir.chdir(@ruby_app_path) do
        spawn("bundle exec #{command}", :out => "/dev/null", :err => "/dev/null")

        Process.wait
      end

      if $?.exitstatus == 0
        @operations << [:run_command, rollback_command || nil]
        true
      else
        false
      end
    end

    def override_file(file, file_to_be_overriden)
      Dir.chdir(@ruby_app_path) do
        fail NoFileToBeOverriden unless File.exists?(file_to_be_overriden)

        FileUtils.mkdir_p("/tmp/reciper")
        filename = File.basename(file_to_be_overriden)
        tmp_file = "/tmp/reciper/#{filename}"

        FileUtils.cp(file_to_be_overriden, tmp_file)

        @operations << [:override_file, tmp_file, file_to_be_overriden]
      end

      FileUtils.cp(@recipe_path + "/" + file, @ruby_app_path + "/" + file_to_be_overriden)
    end

    private

    def create_directory_if_not_exists(directory)
      FileUtils.mkdir_p(directory) unless File.directory?(directory)
    end
  end
end