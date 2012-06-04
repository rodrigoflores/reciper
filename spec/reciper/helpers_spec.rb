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

      @operations.should include([:copy_file, { :destination => "/file.rb" }])
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
    it "returns a hash with successful as true when the rake task has been run successfully" do
      output = <<EOF
a
b
EOF

      io = double(:io)
      io.should_receive(:read) do
        "a\nb\n"
      end

      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      IO.should_receive(:popen).
        with("bundle exec rake puts_something").and_yield(io)
      $?.should_receive(:exitstatus).and_return(0)

      run_rake_task("puts_something").should == {
        :response => "a\nb\n",
        :successful => true
      }
    end

    it "returns a hash with successful as false when the rake task hasn't been run successfully" do

      output = ""

      io = double(:io)
      io.stub!(:read).and_return("")

      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      IO.should_receive(:popen).
        with("bundle exec rake puts_something").and_yield(io)
      $?.should_receive(:exitstatus).and_return(1)

      run_rake_task("puts_something").should == {
        :response => "",
        :successful => false
      }
    end
  end

  describe ".copy_line_range" do
    it "copies the entire input file to the output line on a specified line" do
      readme = <<-EOF
d
e
EOF

      original = <<-EOF
a
b
c
f
EOF

      Dir.should_receive(:glob).with("spec/fixtures/ruby_app/README.md").
        and_return(["spec/fixtures/ruby_app/README.md"])

      File.should_receive(:read).with("spec/fixtures/recipe/README").
        and_return(readme)

      File.should_receive(:read).with("spec/fixtures/ruby_app/README.md").
        and_return(original)

      file = double(:file)
      file.should_receive(:write).with("a\nb\nc\nd\ne\nf")
      File.should_receive(:open).with("spec/fixtures/ruby_app/README.md", "w").and_yield(file)

      copy_line_range("README", "README.md", :to_line => 3)
    end

    it "copies only specified lines" do
      readme = <<-EOF
a
d
e
f
g
EOF

      original = <<-EOF
a
b
c
f
EOF

      Dir.should_receive(:glob).with("spec/fixtures/ruby_app/README.md").
        and_return(["spec/fixtures/ruby_app/README.md"])

      File.should_receive(:read).with("spec/fixtures/recipe/README").
        and_return(readme)

      File.should_receive(:read).with("spec/fixtures/ruby_app/README.md").
        and_return(original)

      file = double(:file)
      file.should_receive(:write).with("a\nb\nc\nd\ne\nf")
      File.should_receive(:open).with("spec/fixtures/ruby_app/README.md", "w").and_yield(file)

      copy_line_range("README", "README.md", :to_line => 3, :lines => (1..2))
    end

    it "adds an entry to operations" do
      readme = <<-EOF
a
d
e
f
g
EOF

      original = <<-EOF
a
b
c
f
EOF

      Dir.stub!(:glob).with("spec/fixtures/ruby_app/README.md").
        and_return(["spec/fixtures/ruby_app/README.md"])

      File.stub!(:read).with("spec/fixtures/recipe/README").
        and_return(readme)

      File.stub!(:read).with("spec/fixtures/ruby_app/README.md").
        and_return(original)

      file = double(:file)
      file.stub!(:write).with("a\nb\nc\nd\ne\nf")
      File.stub!(:open).with("spec/fixtures/ruby_app/README.md", "w").and_yield(file)

      copy_line_range("README", "README.md", :to_line => 3, :lines => (1..2))

      @operations.should include([:copy_line_range, { :original_content => original, :original_file => "spec/fixtures/ruby_app/README.md"}])
    end

    context "suffix copy" do
      it "works with only the suffix of the file when there is only one file" do
        readme = ""
        original = ""

        Dir.should_receive(:glob).with("spec/fixtures/ruby_app/*.md").
          and_return(["spec/fixtures/ruby_app/README.md"])

        File.stub!(:read).with("spec/fixtures/recipe/README").
          and_return(readme)

        File.should_receive(:read).with("spec/fixtures/ruby_app/README.md").
          and_return(original)

        file = double(:file)
        file.stub!(:write)
        File.stub!(:open).with("spec/fixtures/ruby_app/README.md", "w").and_yield(file)

        copy_line_range("README", "*.md", :to_line => 0)
      end

      it "raises an exception when given only the suffix of the file when there is more than one file" do
        readme = ""
        original = ""

        Dir.should_receive(:glob).with("spec/fixtures/ruby_app/*.md").
          and_return(["spec/fixtures/ruby_app/README.md", "spec/fixtures/ruby_app/README2.md"])

        lambda {
          copy_line_range("README", "*.md", :to_line => 0)
        }.should raise_error(Reciper::NoFileOrMultipleFilesFound)
      end
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
        :successful => true
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
        :successful => false
      }
    end

    it "receives the rollback command together with the command and store it on @operations array" do
      run_command("ls", "ls -a")

      @operations.should include([:run_command, { :rollback_command => "ls -a" }])
    end

    it "doesn't require the rollback command to be informed" do
      run_command("ls")

      @operations.should include([:run_command, { :rollback_command => nil}])
    end
  end

  describe ".override_file" do
    it "overrides the file with another file" do
      Dir.should_receive(:chdir).with(@ruby_app_path).and_yield
      File.should_receive(:exists?).with("README").and_return(true)
      FileUtils.should_receive(:mkdir_p).with("/tmp/reciper")

      FileUtils.should_receive(:cp).with("README", "/tmp/reciper/README")
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/README",
       "spec/fixtures/ruby_app/README")

      override_file("README", "README")
    end

    it "raises an error when file doesn't exists" do
      Dir.stub!(:chdir).with(@ruby_app_path).and_yield
      File.should_receive(:exists?).with("README").and_return(false)

      lambda {
        override_file("README", "README")
      }.should raise_error(Reciper::NoFileToBeOverriden)
    end

    it "adds the operation to operations array" do
      Dir.stub!(:chdir).with(@ruby_app_path).and_yield
      File.stub!(:exists?).with("README").and_return(true)
      FileUtils.stub!(:mkdir_p).with("/tmp/reciper")

      FileUtils.stub!(:cp).with("README", "/tmp/reciper/README")
      FileUtils.stub!(:cp).with("spec/fixtures/recipe/README",
       "spec/fixtures/ruby_app/README")

      override_file("README", "README")
      @operations.should include([:override_file, { :tmp_file => "/tmp/reciper/README", :overriden_file => "README"}])
    end
  end

  describe ".rollback" do
    it "removes the file when the operation is copy_file" do
      @operations = [[:copy_file, { :destination => "README" }]]

      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      FileUtils.should_receive(:rm).with("README")

      rollback
    end

    it "restores the old file when the operation is copy_range" do
      @operations = [[:copy_range, { :original_content => "Not OK", :original_file => "an_added_file.rb"}]]

      file = double(:file)
      file.should_receive(:write).with("Not OK")
      File.should_receive(:open).with("an_added_file.rb", "w").and_yield(file)

      rollback
    end

    it "runs the rollback command when the operation is run_command and we have a rollback command" do
      @operations = [[:run_command, { :rollback_command => "ls"}]]

      Dir.should_receive(:chdir).with("spec/fixtures/ruby_app").and_yield

      output = ""

      io = double(:io)
      io.should_receive(:read) do
        ""
      end

      IO.should_receive(:popen).with("ls").and_yield(io)
      $?.should_receive(:exitstatus).and_return(0)

      rollback
    end

    it "runs the rollback command when the operation is override_file" do
      @operations = [[:override_file, { :tmp_file => "/tmp/reciper/my_file.rb", :overriden_file => "ola.rb"}]]

      FileUtils.should_receive(:cp).with("/tmp/reciper/my_file.rb", "spec/fixtures/ruby_app/ola.rb")

      rollback
    end
  end
end