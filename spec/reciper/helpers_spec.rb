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
      File.exists?("spec/fixtures/ruby_app/file.rb").should_not be

      copy_file("file.rb")

      File.exists?("spec/fixtures/ruby_app/file.rb").should be

      FileUtils.rm("spec/fixtures/ruby_app/file.rb")
    end

    it "copies the file from the recipe path to the ruby app" do
      File.exists?("spec/fixtures/ruby_app/lib/file.rb").should_not be

      copy_file("file.rb", :to => "lib")

      File.exists?("spec/fixtures/ruby_app/lib/file.rb").should be

      FileUtils.rm("spec/fixtures/ruby_app/lib/file.rb")
    end

    it "if the dir doesn't exists, create it" do
      File.exists?("spec/fixtures/ruby_app/lib/file.rb").should_not be

      copy_file("file.rb", :to => "my_awesome_dir")

      File.exists?("spec/fixtures/ruby_app/my_awesome_dir/file.rb").should be

      FileUtils.rm_rf("spec/fixtures/ruby_app/my_awesome_dir")
    end

    it "adds the operation to @operation array" do
      copy_file("file.rb")

      @operations.should include([:copy, "file.rb"])

      FileUtils.rm("spec/fixtures/ruby_app/file.rb")
    end

  end

  describe ".run_tests" do
    it "returns 0 if all tests pass" do
      run_tests.should == 0
    end

    it "returns 1 if there is only one failure" do
      copy_file("failing_spec.rb", :to => "spec")

      run_tests.should == 1

      FileUtils.rm("spec/fixtures/ruby_app/spec/failing_spec.rb")
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
    end
  end
end