require "spec_helper"

describe Reciper::Helpers do
  before do
    File.stub!(:directory?).with("./tmp/a_random_recipe").and_return(false)
    FileUtils.stub!(:cp_r)
  end

  let(:recipe) do
    Reciper.new("a random recipe", "spec/fixtures/recipe", "spec/fixtures/ruby_app")
  end

  describe ".copy_file" do
    it "copies the file from the recipe path to the ruby app root path " do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "./tmp/a_random_recipe/file.rb")

      recipe.execute do
        copy_file("file.rb")
      end
    end

    it "copies the file from the recipe path to the ruby app" do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "./tmp/a_random_recipe/lib/file.rb")

      File.stub!(:directory?).with("./tmp/a_random_recipe/lib").and_return(true)

      recipe.execute do
        copy_file("file.rb", :to => "lib")
      end
    end

    it "copies the file with the name as in defined in as" do
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "./tmp/a_random_recipe/another_file.rb")

      recipe.execute do
        copy_file("file.rb", :as => "another_file.rb")
      end
    end

    it "if the dir doesn't exists, create it" do
File.should_receive(:directory?).with("./tmp/a_random_recipe/my_awesome_dir").and_return(false)
      FileUtils.should_receive(:mkdir_p).with("./tmp/a_random_recipe/my_awesome_dir")
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/file.rb", "./tmp/a_random_recipe/my_awesome_dir/file.rb")

      recipe.execute do
        copy_file("file.rb", :to => "my_awesome_dir")
      end
    end
  end

  describe ".run_tests" do
    it "returns 0 if all tests pass" do
      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield

      test_output = <<-EOF
      ....

      Finished in 11.29 seconds
      23 examples, 0 failures
      EOF

      io = double(:io, :read => test_output)
      IO.should_receive(:popen).with("bundle exec rspec spec").and_yield(io)

      recipe.execute do
        run_tests.should == 0
      end
    end

    it "returns 1 if there is only one failure" do
      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield

      test_output = <<-EOF
      FE..

      Finished in 11.29 seconds
      4 examples, 2 failures
      EOF

      io = double(:io, :read => test_output)
      IO.should_receive(:popen).with("bundle exec rspec spec").and_yield(io)

      recipe.execute do
        run_tests.should == 2
      end
    end
  end

  describe ".run_rake_task" do
    it "returns a hash with successful as true when the rake task has been run successfully" do
      output = ""

      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield

      io = double(:io)
      io.stub!(:read).and_return("")

      IO.should_receive(:popen).
        with("bundle exec rake puts_something").and_yield(io)

      $?.should_receive(:exitstatus).and_return(0)

      recipe.execute do
        run_rake_task("puts_something").should == {
          :response => "",
          :successful => true
        }
      end
    end

    it "returns a hash with successful as false when the rake task hasn't been run successfully" do
      output = ""

      io = double(:io)
      io.stub!(:read).and_return("")

      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield

      IO.should_receive(:popen).
        with("bundle exec rake puts_something").and_yield(io)
      $?.should_receive(:exitstatus).and_return(1)

      recipe.execute do
        run_rake_task("puts_something").should == {
          :response => "",
          :successful => false
        }
      end
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

      Dir.should_receive(:glob).with("./tmp/a_random_recipe/README.md").
        and_return(["./tmp/a_random_recipe/README.md"])

      File.should_receive(:read).with("./tmp/a_random_recipe/README.md").
        and_return(original)

      File.should_receive(:read).with("spec/fixtures/recipe/README").
        and_return(readme)

      file = double(:file)
      file.should_receive(:write).with("a\nb\nc\nd\ne\nf")

      recipe.execute do
        File.should_receive(:open).with("./tmp/a_random_recipe/README.md", "w").and_yield(file)

        copy_line_range("README", "README.md", :to_line => 3)
      end
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

      Dir.should_receive(:glob).with("./tmp/a_random_recipe/README.md").
        and_return(["./tmp/a_random_recipe/README.md"])

      File.should_receive(:read).with("spec/fixtures/recipe/README").
        and_return(readme)

      File.should_receive(:read).with("./tmp/a_random_recipe/README.md").
        and_return(original)

      file = double(:file)
      file.should_receive(:write).with("a\nb\nc\nd\ne\nf")

      recipe.execute do
        File.should_receive(:open).with("./tmp/a_random_recipe/README.md", "w").and_yield(file)

        copy_line_range("README", "README.md", :to_line => 3, :lines => (1..2))
      end
    end

    context "suffix copy" do
      it "works with only the suffix of the file when there is only one file" do
        readme = ""
        original = ""

        Dir.should_receive(:glob).with("./tmp/a_random_recipe/*.md").
          and_return(["./tmp/a_random_recipe/README.md"])

        File.stub!(:read).with("spec/fixtures/recipe/README").
          and_return(readme)

        File.should_receive(:read).with("./tmp/a_random_recipe/README.md").
          and_return(original)

        file = double(:file)
        file.stub!(:write)

        recipe.execute do
          File.stub!(:open).with("./tmp/a_random_recipe/README.md", "w").and_yield(file)

          copy_line_range("README", "*.md", :to_line => 0)
        end
      end

      it "raises an exception when given only the suffix of the file when there is more than one file" do
        readme = ""
        original = ""

        Dir.should_receive(:glob).with("./tmp/a_random_recipe/*.md").
          and_return(["spec/fixtures/ruby_app/README.md", "spec/fixtures/ruby_app/README2.md"])

        lambda {
          recipe.execute do
            copy_line_range("README", "*.md", :to_line => 0)
          end
        }.should raise_error(Reciper::NoFileOrMultipleFilesFound)
      end
    end
  end

  describe ".run_command" do
    it "runs a command on projects folder and returns the command hash with the response and true when successful" do
      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield

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

      recipe.execute do
        run_command("ls").should == {
          :response => "a\nb\n",
          :successful => true
        }
      end
    end

    it "runs a command on projects folder and returns the command hash with the response and false when not successful" do
      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield

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

      recipe.execute do
        run_command("ls").should == {
          :response => "a\nb\n",
          :successful => false
        }
      end
    end
  end

  describe ".override_file" do
    it "overrides the file with another file" do
      Dir.should_receive(:chdir).with("./tmp/a_random_recipe").and_yield
      File.should_receive(:exists?).with("README").and_return(true)
      FileUtils.should_receive(:cp).with("spec/fixtures/recipe/README",
       "./tmp/a_random_recipe/README")

      recipe.execute do
        override_file("README", "README")
      end
    end

    it "raises an error when file doesn't exists" do
      Dir.stub!(:chdir).with("./tmp/a_random_recipe").and_yield
      File.should_receive(:exists?).with("README").and_return(false)

      lambda {
        recipe.execute do
          override_file("README", "README")
        end
      }.should raise_error(Reciper::NoFileToBeOverriden)
    end
  end
end