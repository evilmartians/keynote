[![Gem Version](https://badge.fury.io/rb/keynote.svg)](https://rubygems.org/gems/keynote)
[![Build](https://github.com/evilmartians/keynote/workflows/Build/badge.svg)](https://github.com/evilmartians/keynote/actions)

# Keynote

> [!TIP]
> Flexible presenters for Rails.

A presenter is an object that encapsulates view logic. Like Rails helpers,
presenters help you keep complex logic out of your templates.

Keynote provides a consistent interface for defining and instantiating
presenters.

## Requirements

- Ruby >= 3.0.0
- Rails >= 7.0

For older Ruby and Rails versions, you can use Keynote <2.0.

## Usage

Add Keynote to your Gemfile:

```ruby
gem "keynote", "~> 2.0"
```

Don't forget to run `bundle install`.

### The basic idea

A simple case is making a presenter that's named after a model class and holds
helper methods related to that model.

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < Keynote::Presenter
  presents :user

  def display_name
    "#{user.first_name} #{user.last_name}"
  end

  def profile_link
    link_to user, display_name, data: {user_id: user.id}
  end
end
```

You can then instantiate it by calling the `present` method (aliased to `k`) in
a view, helper, controller, or another presenter.

``` erb
<%# app/layouts/_header.html.erb %>

<div id="header">
  ...
  <div class="profile_link">
    <%= k(current_user).profile_link %>
  </div>
</div>
```

If you pass anything other than a symbol or string as the first parameter of
`present`/`k`, Keynote will assume you want to instantiate a presenter named
after the class of that object -- in this case, the model is a `User`, so
Keynote looks for a class called `UserPresenter`.

### Generating HTML

To make it easier to generate slightly more complex chunks of HTML, Keynote provides several ways to generate HTML fragments.

#### Using `build_html`

Keynote includes a modified version of Magnus Holm's [Rumble](https://github.com/judofyr/rumble)
library. Rumble gives us a simple block-based syntax for generating HTML
fragments. Here's a small example:

```ruby
build_html do
  div id: :content do
    h1 "Hello World", class: :main
  end
end
```

Becomes:

```html
<div id="content">
  <h1 class="main">Hello World</h1>
</div>
```

You can use tag helpers like `div`, `span`, and `a` only within a block passed
to the `build_html` method. The `build_html` method returns a safe string. See
[the documentation for `Keynote::Rumble`](http://rubydoc.info/gems/keynote/Keynote/Rumble)
for more information.

#### Using inlined partials

You can extend your presenter class with the `Keynote::Inline` module to enable inline templating in any template language supported by Rails. This is useful for small, self-contained templates that don't need to be extracted into separate files.

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < Keynote::Presenter
  presents :user

  include Keynote::Inline
  # To user Haml or Slim, enabled them explicitly
  # inline :haml, :slim

  def profile_link
    erb do
      <<~ERB
        <div class="profile_link">
          <%= link_to user, display_name, data: { user_id: user.id } %>
          <i class="fa-user"></i>
        </div>
      ERB
    end
  end
end
```

### A more complex example

Let's add to our original example by introducing a named presenter. In addition
to `UserPresenter`, which has general-purpose methods for displaying the User
model, we'll create `HeaderPresenter`, which has methods that are specific to
the `layouts/header` partial.

``` ruby
# app/presenters/header_presenter.rb

class HeaderPresenter < Keynote::Presenter
  presents :user

  def profile_or_login_link
    if logged_in? # defined in a helper
      profile_link
    else
      login_link
    end
  end

  def profile_link
    build_html do
      div class: 'profile_link' do
        k(user).profile_link
      end
    end
  end

  def login_link
    build_html do
      div class: 'login_link' do
        link_to 'Log In', login_url
      end
    end
  end
end
```

``` erb
<%# app/layouts/_header.html.erb %>

<% header = present(:header, current_user) %>

<div id="header">
  ...
  <%= header.profile_or_login_link %>
</div>
```

We've avoided putting a conditional in the template, and we've also avoided
exposing the `profile_or_login_link` method to other parts of the app that
shouldn't need to care about it. It's located in a class that's specific to
this context.

### Delegating to models

If you want to delegate some calls on the presenter to one of the presenter's
underlying objects, it's easy to do it explicitly with ActiveSupport's
`delegate` API.

``` ruby
# app/presenters/user_presenter.rb

class UserPresenter < Keynote::Presenter
  presents :user
  delegate :first_name, :last_name, to: :user

  def display_name
    "#{first_name} #{last_name}"
  end
end
```

You can also generate prefixed methods like `user_first_name` by passing
`prefix: true` to the `delegate` method.

## Testing

Testing a Keynote presenter is similar to using it in views or controllers. You
can test presenters with RSpec, Test::Unit, MiniTest, or MiniTest::Unit.

### RSpec

Your test files should be in `spec/presenters` or labeled with
[`type: :presenter` metadata].

Here's an example:

```ruby
# spec/presenters/user_presenter_spec.rb

RSpec.describe UserPresenter do
  describe "#display_name" do
    it "returns the name of the user" do
      user = User.new(first_name: "Alice", last_name: "Smith")

      expect(present(user).display_name).to eq("Alice Smith")
    end
  end
end
```

### MiniTest

Your test classes should inherit from Keynote::TestCase.

```ruby
class UserPresenterTest < Keynote::TestCase
  setup do
    user = User.new(first_name: "Alice", last_name: "Smith")
    @presenter = present(user)
  end

  test "display name" do
    assert_equal @presenter.display_name, "Alice Smith"
  end
end
```

## Rationale

### Why use presenters or decorators at all

The main alternative is to use helpers. Helpers are fine for many use cases --
Rails' built-in tag and form helpers are great. They have some drawbacks,
though:

- Every helper method you write gets mixed into the same view object as the
  built-in Rails helpers, URL generators, and all the other junk that comes
  along with `ActionView::Base`. In a freshly-generated Rails project:

  ```ruby
  ApplicationController.new.view_context.public_methods.count
  # => 318
  ApplicationController.new.view_context.private_methods.count
  # => 119
  ```

- Helpers can't have state that isn't "global" relative to the view, which
  can make it hard to write helpers that work together.

- By default, every helper is available in every view. This makes it difficult
  to set boundaries between different parts of your app and organize your view
  code cleanly.

### Why not use decorators

The biggest distinction between Keynote and similar libraries like [Draper] and
[DisplayCase] is that Keynote presenters aren't decorators – undefined method
calls don't fall through to an underlying model.

Applying the Decorator pattern to generating views is a reasonable thing to do.
However, this practice also has some downsides.

- Decorators make the most sense when there's exactly one object that's
  relevant to the methods you want to encapsulate. They're less helpful when
  you want to do things like define a class whose responsibility is to help
  render a specific part of your user interface, which may involve bringing in
  data from multiple models or collections.

- When reading code that uses decorators, it often isn't obvious if a given
  method is defined on the decorator or the underlying model, especially when
  the decorator is applied in the controller instead of the view.

- Passing decorated models between controllers and views can make it unclear
  whether a view (especially a nested partial) depends on a model having some
  specific decorator applied to it. This makes refactoring view and decorator
  code harder than it needs to be.

## Generators

Keynote doesn't automatically generate presenters when you generate models or
resources. To generate a presenter, you can use the `presenter` generator,
like so:

```sh
$ rails g presenter FooBar foo bar
      create  app/presenters/foo_bar_presenter.rb
      create  spec/presenters/foo_bar_presenter_spec.rb
```

That project uses RSpec, but the generator can also create test files for
Test::Unit or MiniTest::Rails if applicable.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/evilmartians/keynote](https://github.com/evilmartians/keynote).

For gem development, clone the repo and run `bundle install` to install the dependencies. Then, run `bundle exec rake` to run the tests.

(Optionally) Run `bundle exec lefthook install` to configure git hooks (so you never miss linter complaints before opening a PR).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[DisplayCase]: https://github.com/objects-on-rails/display-case
[Draper]: https://github.com/drapergem/draper
[Roadshow]: https://github.com/rf-/roadshow
[`type: :presenter` metadata]: https://relishapp.com/rspec/rspec-rails/docs/directory-structure
