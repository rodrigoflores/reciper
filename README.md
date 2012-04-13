# Reciper

Suppose you're writing a book containing some programming recipes. It would be great to have a test suite that ensures that your snippets really are really working. But why we should write a test suite if RSpec already does an awesome job doing it ?

Reciper is a collection of helpers that helps you write tests for your book recipes. It should be included on your described class and used whenever you need to copy files, copy line ranges, run tests, overwrite files, among other things.

## Install

On your `Gemfile`, just do this:

```ruby
gem "reciper"
```
     
Run `bundle install` and on your described class just include `Reciper::Helpers`

```ruby
describe "My awesome recipe" do
  include Reciper::Helpers
  # (...)
end
```

        

