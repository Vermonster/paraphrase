# paraphrase

paraphrase is a DSL to map one or multiple request params to model scopes.

paraphrase was designed and geared towards building a query-based public API
where you may want to require certain parameters to prevent consumers from
scraping all your information or to mitigate the possibility of large,
performance-intensive data-dumps.

## Installation

Via a gemfile:

```ruby
gem 'paraphrase'
```

```
$ bundle
```

Or manually:

```
$ gem install paraphrase
```

## Usage

paraphrase aims to be as flexible as possible for your needs. The only
requirement is a class with chainable methods where the result responds to
`:to_a`. You can use it:

* From within an `ActiveRecord` subclass:

```ruby
class Post < ActiveRecord::Base
  register_mapping do
    scope :by_user, :key => :author
  end

  def self.by_user(author_name)
    joins(:user).where(:user => { :name => author_name })
  end
end
```

* In an initializer to register multiple mappings in one place:

```ruby
# config/initializers/paraphrase.rb

Paraphrase.configure do |mappings|
  mappings.register :Post do
    paraphrases Post
    scope :by_user, :key => :author
  end
end
```

* By creating a subclass of `Paraphrase::Query`:

```ruby
class PostQuery < Paraphrase::Query
  paraphrases Post

  scope :by_user, :key => :author
end
```

Then in a controller you can use it in any of the following ways:

```ruby
class PostsController < ApplicationController
  respond_to :html, :json

  def index
    # Filters out relevant attributes
    # and applies scopes relevant to each
    # parameter
    @posts = Post.paraphrase(params)

    # Or
    # @posts = Paraphrase.query(:Post, params)

    # If you created a subclass
    # @posts = PostParaphrase.new(params)

    respond_with(@posts)
  end
end
```

In any of these contexts, the `:key` option of the `:scope` method registers
attribute(s) to extract from the params supplied and what scope to pass them
to. An array of keys can be supplied to pass multiple attributes to a scope.
Additionally, there is a `:preprocess` option to prepare values for the scope
to be called.

```ruby
class Post < ActiveRecord::Base
  register_mapping do
    scope :by_user, :key => [:first_name, :last_name], :preprocess => lambda { |first, last| [first, last].join(' ') }
  end

  def self.by_user(name)
    joins(:user).where(:user => { :name => name })
  end
end
```

If a key is required, passed `:required => true` to the options. This will
return an empty results set

```ruby
class Post < ActiveRecord::Base
  register_mapping do
    scope :by_author, :key => :author, :required => true
    scope :published_after, :key => :pub_date
  end
end

Poast.paraphrase(:pub_date => '2010-10-30') # => []
```

## Thoughts on the future

1. Smooth out preprocess syntax/reconsider its usefulness.
2. Enable requiring a subset of a compound key.
3. Support nested hashes in params.
4. Better sort how keys in `Paraphrase.mappings` are set.
