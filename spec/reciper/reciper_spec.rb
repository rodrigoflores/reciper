require "spec_helper"

describe Reciper do
  describe "#initialize" do
    before do
      File.stub!(:directory?).and_return(false)
      FileUtils.stub!(:cp_r)
      FileUtils.stub!(:mkdir_p).with("tmp")
    end

    it "assigns the paths" do
      reciper = described_class.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")

      reciper.ruby_app_path.should == "./tmp/awesome_recipe"
      reciper.recipe_path.should == "~/Code/source_path"
    end

    it "removes the temp directory if it exists and copies a new version" do
      File.should_receive(:directory?).
        with("./tmp/awesome_recipe").and_return(true)

      FileUtils.should_receive(:rm_rf).with("./tmp/awesome_recipe")

      described_class.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")
    end

    it "creates the temp directory" do
      FileUtils.should_receive(:cp_r).with("~/Code/rails_app", "./tmp/awesome_recipe")
      FileUtils.should_receive(:mkdir_p).with("tmp")

      described_class.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")
    end
  end

  describe "#execute" do
    it "run an instance eval with all paths" do
      File.stub!(:directory?).and_return(false)
      FileUtils.stub!(:cp_r)
      FileUtils.stub!(:mkdir_p).with("tmp")

      reciper = described_class.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")

      reciper.execute do
        @ruby_app_path.should == "./tmp/awesome_recipe"
        @recipe_path.should == "~/Code/source_path"
      end
    end
  end
end