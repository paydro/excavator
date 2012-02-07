# Excavator

Excavator is a commandline scripting framework. It takes care of parameter
parsing, command namespacing and command loading so that you can focus on
writing your scripts.

Excavator is like a stripped down version of rake but uses optparse for
parameter parsing.

Here's a simple, albeit contrived, example of what you can do with Excavator.

    require 'excavator'

    param :name
    command :hello do
      puts "Hello, #{params[:name]}!"
    end

    Excavator.run(ARGV)

Place the previous contents in a file named `say` and then run it:

    $ chmod a+x say
    $ say hello --name paydro
    Hello, paydro!
    $


# Installation

    gem install excavator

# Usage

Excavator does not come with a commandline tool. The way to use Excavator is to first create an executable file, then add commands in the file.

Creating the file:

    $ touch my_commands
    $ chmod a+x my_commands

Edit `my_commands` and add the following:

    #!/usr/bin/env ruby
    require 'excavator'

    namespace :happy_quotes do
      commands :smile do
        # ...
      end
    end

    namespace :jokes do
      commands :knock_knock do
        # ...
      end
    end

    Excavator.run(ARGV) # This runs it

Now you can execute the commands.

    $ my_commands jokes:knock_knock
    ...
    $ my_commands happy_quotes:smile
    ...
    $

When the commands pile up, you can move them to other files and tell Excavator where all your commands live.

For instance, let's assume we have the same `my_commands` script above, but we also add the directory `commands/`. In `commands/`, we refactor the previous commands from `my_commands`. The file hiearchy now looks like this:

    /Users/paydro/
      commands/
        happy_quotes.rb
        jokes.rb
      my_commands # The original file

Now, inside `my_commands`, all we have is this:

    #!/usr/bin/env ruby
    require 'excavator'
    Excavator.command_paths = ["/Users/paydro/commands"]
    Excavator.run(ARGV)

By default, Excavator already looks into the `commands/` if it exists next to
the script, but it's shown above for completeness.

## Commands

Commands are created with the `command` method.

    command :list do
      # ...
    end

    command :another do
      # ...
    end

### Call Other Commands

Use `execute` to call other commands from within a command.

    command :print do
      execute :my_name
    end

    command :my_name do
      puts "paydro"
    end

You can even pass parameters to other commands with a hash.

    # Prints "paydro"
    command :print do
      execute :my_name, :name => "paydro"
    end

    param :name
    command :my_name do
      puts params[:name]
    end


## Command Description

Describe your command using the `desc` method above the command definition.

    desc "Prints all the servers in the cluster"
    command :list_servers do
      # ...
    end

## Namespaces

Group similar or related commands via `namespace`.

    # Creates the following commands:
    # - servers:list
    # - servers:create
    # - servers:boot:with_ruby

    namespace :servers do
      command :list do
        # ...
      end

      command :create do
        # ...
      end

      namespace :boot do
        command :with_ruby do
          # ...
        end
      end
    end

## Parameters

Parameters are available within the command body via the `params`.

    param :first_name
    param :last_name
    command :print do
      puts params[:first_name]
      puts params[:last_name]
    end

### Required, Optional, Defaults

Params are required by default. To make them optional, specify the optional flag or specify a default

    # Required - if not passed, will stop the script
    param :first_name

    # Optional
    param :last_name, :optional => true

    # Optional - has a default
    param :country, :default => "USA"
    command :print do
      puts params[:first_name]
      puts params[:last_name] # Might be nil!
      puts params[:country] # USA unless something was passed
    end

### Description

Params can take descriptions so that the script can print them out with `-h`.

    param :last_name, :desc => "Your last name"


### Long and Short Switches

Parameters are assigned long and short switches unless they are specified. The
short switch is usually the first character in the name of the param. If there
are duplicates, then the param parser will continue to move to the next
character in the name until it finds a unique character. If it cannot find a
unique character, then the parameter will not have a short switch.

    # --abc, -a
    param :abc

    # --bc, -b
    param :bc

    # --ab
    # "a" and "b" are already taken above, so this one doesn't have a short
    # switch
    param :ab

    # Force a short switch, -c
    param :aabb, :short => "c"

## Help Commands

You can list all commands you've created by calling your script with `--help`, `-h`, or `-?`. This will print out all the commands and their descriptions for you.

    # Lists all commands (assuming our commands are in "servers")
    $ servers --help
    ... prints out commands ...
    $

To view the usage of a single command, pass the `-h` or `--help` switch when
calling the command.

    # Lists usage of "list" (assuming our commands are in "servers")
    $ servers list -h
    ... usage ...
    $


# Add Helpers For Commands

Commands run within and instance of `Excavator::Environment`, and it has a few methods that you can use. To extend this, you can use `Excavator::Environment#modify`. This is really just a helper give you access to the `Excavator::Environment` scope (i.e., for including other modules).

    require 'excavator'

    module Helpers
      def hello
        puts "hello!"
      end
    end

    module ExpensiveHTTPCalls
      # ...
    end

    Excavator.environment_class.modify Helpers, ExpensiveHTTPCalls

    # OR

    Excavator.environment_class.modify do
      include Helpers
    end

    command :example do
      hello
    end

# Contrib

## Bugs

Submit bugs [on GitHub](https://github.com/paydro/excavator/issues).

## Hacking

Please fork the [repository](https://github.com/paydro/excavator) on GitHub and send me a pull request. Here's a few guidelines:

* Use 80 character columns
* Write tests!
* Follow other examples in the code

# Credits

[Peter Bui](peter@paydrotalks.com)
