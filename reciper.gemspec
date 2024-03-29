# -*- encoding: utf-8 -*-
require File.expand_path('../lib/reciper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rodrigo Flores"]
  gem.email         = ["mail@rodrigoflores.org"]
  gem.description   = %q{An awesome way to write recipes for a book chapter}
  gem.summary       = %q{An awesome way to write recipes for a book chapter}
  gem.homepage      = "http://github.com/rodrigoflores/reciper"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "reciper"
  gem.require_paths = ["lib"]
  gem.version       = Reciper::VERSION

  gem.add_dependency("activesupport", "3.2.5")
end
