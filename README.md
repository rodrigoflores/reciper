# Reciper

Suppose you're writing a book containing some programming recipes. It would be great to have a test suite that ensures that your snippets really are really working. But why we should write a test suite if RSpec already does an awesome job doing it ?

Reciper is a collection of helpers that helps you write tests for your book recipes. It should be included on your described class and used whenever you need to copy files, copy line ranges, run tests, overwrite files, among other things.

## Installation

On your `Gemfile`, just do this:

```ruby
gem "reciper"
```
     
Run `bundle install` and you're ready to go!

## Usage

Usage is really simple:

```ruby
Recipe.new("My recipe name", "recipe_path/code", "ruby_app_template").execute do
  copy_file("file.rb", :as => "user.rb", :to => "app/models")
end
```