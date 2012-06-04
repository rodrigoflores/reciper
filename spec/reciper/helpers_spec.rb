require "spec_helper"

describe Reciper::Helpers do
  include Reciper::Helpers

  before(:all) do
    @ruby_app_path = "spec/fixtures/ruby_app"
    @recipe_path = "spec/fixtures/recipe"
  end

  before(:each) do
    @operations = []
  end

  describe ".copy" do
    it "copies the file from the recipe path to the ruby app root path " do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "spec/fixtures/ruby_app/file.rb")

      copy_file("file.rb")
    end

    it "copies the file from the recipe path to the ruby app" do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "spec/fixtures/ruby_app/lib/file.rb")

      copy_file("file.rb", :to => "lib")
    end

    it "copies the file with the name as in defined in as" do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "spec/fixtures/ruby_app/another_file.rb")

      copy_file("file.rb", :as => "another_file.rb")
    end

    it "if the dir doesn't exists, create it" do
      directory = @ruby_app_path + "/my_awesome_dir"
      File.should_receive(:directory?).with("spec/fixtures/ruby_app/my_awesome_dir").and_return(false)
      FileUtils.should_receive(:mkdir_p).with("spec/fixtures/ruby_app/my_awesome_dir")
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "spec/fixtures/ruby_app/my_awesome_dir/file.rb")

      copy_file("file.rb", :to => "my_awesome_dir")
    end

    it "adds the operation to @operation array" do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "spec/fixtures/ruby_app/file.rb")

      copy_file("file.rb")

      @operations.should include([:copy, { :destination => "/file.rb" }])
    end
  end

  describe ".run_tests" do
    it "returns 0 if all tests pass" do
      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      test_output = <<-EOF
      ....

      Finished in 11.29 seconds
      23 examples, 0 failures
      EOF

      io = double(:io, :read => test_output)
      IO.should_receive(:popen).with("bundle exec rspec spec").and_yield(io)

      run_tests.should == 0
    end

    it "returns 1 if there is only one failure" do
      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      test_output = <<-EOF
      FE..

      Finished in 11.29 seconds
      4 examples, 2 failures
      EOF

      io = double(:io, :read => test_output)
      IO.should_receive(:popen).with("bundle exec rspec spec").and_yield(io)

      run_tests.should == 2
    end
  end

  describe ".run_rake_task" do
    it "returns true when the rake task has been run ok" do
      run_rake_task("puts_something").should be
    end

    it "returns false when the rake task hasn't been run ok" do
      run_rake_task("idontexists").should_not be
    end
  end

  describe ".copy_line_range" do
    it "copies the entire input file to the output line " do
      @expected_at_the_beginning = <<-EOF
class MyClass
end
EOF
      File.read("spec/fixtures/ruby_app/lib/my_class.rb").should == @expected_at_the_beginning.chomp

      expected_at_the_end = <<-EOF
class MyClass
def my_name
  puts self.name
end
end
EOF

      copy_line_range("my_name.rb", "lib/my_class.rb", :to_line => 2)

      File.read("spec/fixtures/ruby_app/lib/my_class.rb").should == expected_at_the_end.chomp
    end

    it "copies only specified lines" do
      @expected_at_the_beginning = <<-EOF
class MyClass
end
EOF

      File.read("spec/fixtures/ruby_app/lib/my_class.rb").should == @expected_at_the_beginning.chomp

      expected_at_the_end = <<-EOF
class MyClass
  puts self.name
end
EOF

      copy_line_range("my_name.rb", "lib/my_class.rb", :to_line => 2, :from_lines => (2..2))

      File.read("spec/fixtures/ruby_app/lib/my_class.rb").should == expected_at_the_end.chomp
    end

    context "suffix copy" do
      it "works with only the suffix of the file when there is only one file" do
        @expected_at_the_beginning = <<-EOF
class MyClass
end
EOF

        File.read("spec/fixtures/ruby_app/lib/my_class.rb").should == @expected_at_the_beginning.chomp

        expected_at_the_end = <<-EOF
class MyClass
  puts self.name
end
EOF

        copy_line_range("my_name.rb", "lib/*_class.rb", :to_line => 2, :from_lines => (2..2))

        File.read("spec/fixtures/ruby_app/lib/my_class.rb").should == expected_at_the_end.chomp
      end

      it "doesn't works with only the suffix of the file when there is more than one file" do
        @expected_at_the_beginning = <<-EOF
class MyClass
end
EOF

        lambda {
          copy_line_range("my_name.rb", "*", :to_line => 2, :from_lines => (2..2))
        }.should raise_error Reciper::NoFileOrMultipleFilesFound
      end
    end

    it "adds an entry to operations" do
      @expected_at_the_beginning = <<-EOF
class MyClass
end
EOF

      copy_line_range("my_name.rb", "lib/my_class.rb", :to_line => 2)

      @operations.should include([:copy_range, "lib/my_class.rb", @expected_at_the_beginning.chomp])
    end

    after do
      File.write("spec/fixtures/ruby_app/lib/my_class.rb", @expected_at_the_beginning.chomp)
    end
  end

  describe ".run_command" do
    it "runs a command on projects folder and returns the command hash with the response and true when successful" do
      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      output = <<EOF
a
b
EOF

      io = double(:io)
      io.should_receive(:read) do
        "a\nb\n"
      end

      IO.should_receive(:popen).with("ls").and_yield(io)
      $?.should_receive(:exitstatus).and_return(0)

      run_command("ls").should == {
        :response => "a\nb\n",
        :succesful => true
      }
    end

    it "runs a command on projects folder and returns the command hash with the response and false when not successful" do
      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      output = <<EOF
a
b
EOF

      io = double(:io)
      io.should_receive(:read) do
        "a\nb\n"
      end

      IO.should_receive(:popen).with("ls").and_yield(io)
      $?.should_receive(:exitstatus).and_return(1)

      run_command("ls").should == {
        :response => "a\nb\n",
        :succesful => false
      }
    end

    it "receives the rollback command together with the command and store it on @operations array" do
      pending
      run_command("ls", "ls -a")

      @operations.should include([:run_command, "ls -a"])
    end
  end

  describe ".rollback" do
    it "removes the file when the operation is copy" do
      File.open(@ruby_app_path + "/an_added_file.rb", "w") {
        |f| f.write("OK")
      }

      File.exists?("spec/fixtures/ruby_app/an_added_file.rb").should be

      @operations = [[:copy, "an_added_file.rb"]]

      rollback

      File.exists?("spec/fixtures/ruby_app/an_added_file.rb").should_not be
    end

    it "restores the old file when the operation is copy_range" do
      File.open(@ruby_app_path + "/an_added_file.rb", "w") {
        |f| f.write("OK")
      }

      File.read("spec/fixtures/ruby_app/an_added_file.rb").should == "OK"

      @operations = [[:copy_range, "an_added_file.rb", "Not OK"]]

      rollback

      File.read("spec/fixtures/ruby_app/an_added_file.rb").should == "Not OK"

      FileUtils.rm("spec/fixtures/ruby_app/an_added_file.rb")
    end

    it "runs the rollback command when the operation is run_command and we have a rollback command" do
      @operations = [[:run_command, "ls"]]

      self.should_receive(:spawn).with("ls")
      Process.stub!(:wait)

      rollback
    end

    it "runs the rollback command when the operation is override_file" do
      begin
        FileUtils.cp("spec/fixtures/ruby_app/README", "/tmp/README")
        FileUtils.rm("spec/fixtures/ruby_app/README")

        File.exists?("spec/fixtures/ruby_app/README").should_not be

        @operations = [[:override_file, "/tmp/README", "README"]]

        rollback

        File.exists?("spec/fixtures/ruby_app/README").should be
      ensure
        FileUtils.cp("/tmp/README", "spec/fixtures/ruby_app/README") unless File.exists?("spec/fixtures/ruby_app/README")
      end
    end
  end

  describe ".override_file" do
    it "overrides the file with another file" do
      FileUtils.cp("spec/fixtures/ruby_app/README", "/tmp/README")

      File.read("spec/fixtures/ruby_app/README").should == "some content"

      override_file("README", "README")

      File.read("spec/fixtures/ruby_app/README").should == ""

      FileUtils.mv("/tmp/README", "spec/fixtures/ruby_app/README")
    end

    it "adds the operation to operations array" do
      FileUtils.cp("spec/fixtures/ruby_app/README", "/tmp/README")

      override_file("README", "README")

      @operations.should include([:override_file, "/tmp/reciper/README", "README"])

      FileUtils.mv("/tmp/README", "spec/fixtures/ruby_app/README")
    end
  end
end