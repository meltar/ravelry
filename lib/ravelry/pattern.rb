require 'curb'

require_relative 'author'
require_relative 'pack'
require_relative 'yarn_weight'
require_relative 'yarn'
require_relative 'data'

module Ravelry

  # `Ravelry::Pattern` corresponds to Pattern objects in Ravelry.
  #  
  # The `Pattern` object can be passed an id as an integer or a string. See {file:README.md README} for information on accessing pattern IDs.
  # 
  # This class requires your environment variables be set (see {file:README.md README}). API calls are authenticated using HTTP Basic Auth unless otherwise noted.
  # 
  # If your `pattern.data` is missing one of the attributes below, that method will return `nil`.
  # 
  # # `GET` Request
  # 
  # Initializing the class with an id will automatically trigger an API call using your access key and personal key.
  # 
  # ```ruby
  # pattern = Ravelry::Pattern.new("000000")
  # ```
  # 
  # After the call is complete, you have access to all of the pattern attributes through the class methods (see documentation). Example:
  # 
  # ```ruby
  # pattern.free?
  # # => true
  # ```
  # 
  # #Initialization without a pattern id 
  # 
  # If you don't want to perform a `GET` request right out of the gate, simply initialize with no arguments.
  # 
  # ```ruby
  # pattern = Ravelry::Pattern.new
  # ```
  # 
  # To complete the `GET` request, set the `id` and run:
  # 
  # ```ruby
  # pattern.id = "000000"
  # pattern.fetch_and_parse
  # ```
  # 
  # After calling `fetch_and_parse`, you have access to all of the class methods below.
  # 
  # #Initialization with existing pattern data
  # 
  # If you have existing pattern data, you should initialize as follows:
  # 
  # ```ruby
  # pattern = Ravelry::Pattern.new(nil, my_data)
  # ```
  # 
  # You now have access to all class methods for your pattern. Be warned: if you run `fetch_and_parse` again, you will override your data with fresh information from the API call.
  # 
  # # Building associated objects
  # 
  # You will need to call special methods to create the associated objects with your pattern.
  # 
  # To create all associated objects at once, call the following method after initialization:
  # 
  # ```ruby
  # pattern.build_all_objects
  # ```
  # 
  # Note that this does not perform an API call: it creates the objects using the data returned from the initial `fetch_and_parse` for your pattern object.
  # 
  # This will create the following objects and readers from the existing `data`:
  # 
  # * `pattern.author` - an {Ravelry::Author} object
  # * `pattern.packs` - array of {Ravelry::Pack} objects
  # * `pattern.yarns` - array of {Ravelry::Yarn} objects
  # * `pattern.yarn_weights` - array of {Ravelry::YarnWeight} objects
  # 
  # See the documentation for each object's available methods.
  # 
  class Pattern < Data
    attr_reader :author, :yarns, :yarn_weights, :packs

    # Handles API call and parses JSON response. 
    def fetch_and_parse
      c = Curl::Easy.new("https://api.ravelry.com/patterns/#{@id}.json")
      c.http_auth_types = :basic
      c.username = ENV['RAV_ACCESS']
      c.password = ENV['RAV_PERSONAL']
      c.perform
      result = JSON.parse(c.body_str, {symbolize_names: true})
      result[:pattern]
    end

    # Creates all objects associated with your pattern; returns nothing; sets `attr_readers`.
    # 
    # Sets `attr_reader` for:
    # 
    # * `author` - a {Ravelry::Author} object
    # * `packs` - array of {Ravelry::Pack} objects
    # * `yarns` - array of {Ravelry::Yarn} objects
    # * `yarn_weights` - array of {Ravelry::YarnWeight} objects
    # 
    def build_all_objects
      build_authors
      build_packs
      build_yarns
      build_yarn_weights
    end

    # Creates and returns a {Ravelry::Author} object.
    # 
    # See {Ravelry::Author} for more information.
    # 
    def build_authors
      @author = Author.new(data[:pattern_author])
    end

    # Creates and returns an array of {Ravelry::Pack} objects.
    # 
    # See {Ravelry::Pack} for more information.
    # 
    def build_packs
      @packs = []
      packs_raw.each do |pack|
        @packs << Pack.new(nil, pack)
      end
      @packs
    end

    # Creates and returns an array of {Ravelry::Yarn} objects.
    # 
    # See {Ravelry::Yarn} for more information.
    # 
    def build_yarns
      @yarns = []
      packs_raw.each do |pack|
        @yarns << Yarn.new(nil, pack[:yarn])
      end
      @yarns
    end

    # Creates and returns an array of {Ravelry::YarnWeight} objects.
    # 
    # See {Ravelry::YarnWeight} for more information.
    # 
    def build_yarn_weights
      @yarn_weights = []
      packs_raw.each do |pack|
        @yarn_weights << YarnWeight.new(nil, pack[:yarn_weight])
      end
      @yarn_weights
    end

    # Gets comments_count from existing `data`.
    def comments_count
      data[:comments_count]
    end

    # Gets craft_name from existing `data`.
    def craft_name
      data[:craft][:name]
    end

    # Gets craft_permalink from existing `data`.
    def craft_permalink
      data[:craft][:permalink]
    end

    # Gets currency from existing `data`.
    def currency
      data[:currency]
    end

    # Gets currency_symbol from existing `data`.
    def currency_symbol
      data[:currency_symbol]
    end

    # Returns the difficult average as a Float (this is how it is stored by Ravelry).
    def difficulty_average_float
      data[:difficulty_average]
    end

    # Returns the difficulty average rounded up or down to an Integer.
    def difficulty_average_integer
      difficulty_average_float.round(0)
    end

    # Gets difficulty_count (Integer) from existing `data`.
    def difficulty_count
      data[:difficulty_count]
    end

    # Returns true if the pattern can be downloaded.
    def downloadable?
      data[:downloadable]
    end

    # Gets favorites_count (Integer) from existing `data`.
    def favorites_count
      data[:favorites_count]
    end

    # Returns true if pattern is free (Boolean).
    def free?
      data[:free]
    end

    # Number of stitches per inch (or 4 inches) (Float).
    def gauge
      data[:gauge]
    end

    # Sentence description of sts and row gauge with stitch.
    def gauge_description
      data[:gauge_description]
    end

    # Either 1 or 4 (inches) (Integer).
    def gauge_divisor
      data[:gauge_divisor]
    end

    # Pattern for gauge listed.
    def gauge_pattern
      data[:gauge_pattern]
    end

    # Gets patter name from existing `data`.
    def name
      data[:name]
    end

    # Raw pattern notes. May be mixed Markdown and HTML. Generally only useful when presenting a pattern notes editor.
    def notes_raw
      data[:notes]
    end

    # Pattern notes rendered as HTML.
    def notes_html
      data[:notes_html]
    end

    # Returns an array of hashes with tons of information about each yarn listed in the pattern. See {#build_packs} for a complete list of helper methods.
    # 
    # I've included this method in case you want to have more control over how your pack information is displayed. It's likely that you'll want to use the other pack methods. While you sacrifice some fine tuning control, you also don't have to worry about dealing with a messy nested hash.
    # 
    # If you're really determined to go through this manually, check out the [Ravelry documentation](http://www.ravelry.com/api#Pack_result).
    # 
    # If iterating through the `packs` hash, you'll likely want to do something like this:
    # 
    # `packs = pattern.packs`
    # 
    # **`packs[0][:yarn_name]`** returns a formatted string with the brand and yarn name.
    # 
    # *Example: "Wooly Wonka Fibers Artio Sock"*
    # 
    def packs_raw
      data[:packs]
    end

    # Helper that will tell you how many yarns you have in your pack.
    def pack_count
      data[:packs].length
    end

    # Returns a hash with information about the pattern author.
    # 
    # I've included this method in case you want to have more control over how your author information is displayed.
    # 
    # See {#build_authors} for more information about directly accessing author information.
    # 
    def pattern_author
      data[:pattern_author]
    end

  end

end