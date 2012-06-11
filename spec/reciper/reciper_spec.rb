require "spec_helper"

describe Reciper do
  describe "#initialize" do
    before do
      File.stub!(:directory?).and_return(false)
      FileUtils.stub!(:cp_r)
    end

    it "assigns the paths" do
      reciper = Reciper.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")

      reciper.ruby_app_path.should == "./tmp/awesome_recipe"
      reciper.source_path.should == "~/Code/source_path"
    end

    it "removes the temp directory if it exists and copies a new version" do
      File.should_receive(:directory?).
        with("./tmp/awesome_recipe").and_return(true)

      FileUtils.should_receive(:rm_rf).with("./tmp/awesome_recipe")

      Reciper.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")
    end

    it "creates the temp directory" do
      FileUtils.should_receive(:cp_r).with("~/Code/rails_app", "./tmp/awesome_recipe")

      Reciper.new("Awesome recipe", "~/Code/source_path", "~/Code/rails_app")
    end
  end

  describe "#execute" do
    it "run an instance eval" do
      pending
    end
  end
end