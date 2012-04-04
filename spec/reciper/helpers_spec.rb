require "spec_helper"

describe Reciper::Helpers do
  include Reciper::Helpers

  before(:all) do
    @ruby_app_path = "spec/fixtures/ruby_app"
    @recipe_path = "spec/fixtures/recipe"
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
end