require "fileutils"

# def copy(filename, options={})
#   log "Let's verify if #{@rails_app_path + "/" + (options[:to] || "")} exists"
#
#   destination_dir = @rails_app_path + "/" + (options[:to] || "")
#
#   unless File.directory?(destination_dir)
#     log "Nope, it doesn't. Creating it"
#     FileUtils.mkdir_p(destination_dir)
#   end
#
#   log "Copying #{@recipe_path + "/" + filename} to #{destination_dir}"
#
#   FileUtils.cp(@recipe_path + "/" + filename, destination_dir)
#
#   @operations << [:copy, destination_dir + "/" + filename]
# end

module Helpers
  def copy_file(filename, options={})
    destination_dir = @ruby_app_path + "/" + (options[:to] || "")

    unless File.directory?(destination_dir)
      FileUtils.mkdir_p(destination_dir)
    end

    FileUtils.cp(@recipe_path + "/" + filename, destination_dir)
  end
end