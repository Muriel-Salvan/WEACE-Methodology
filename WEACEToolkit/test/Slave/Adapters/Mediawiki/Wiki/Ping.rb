# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require "#{File.dirname(__FILE__)}/../Common"

module WEACE

  module Test

    module Slave

      module Adapters

        module Mediawiki

          module Wiki

            class Ping < ::Test::Unit::TestCase

              include WEACE::Test::Slave::GenericAdapters::Wiki::Ping
              include WEACE::Test::Slave::Adapters::Mediawiki::Common

              # Prepare the plugin's execution
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iComment* (_String_): The Ping comment
              # * *CodeBlock*: Code to call once preparation has been made
              def prepareExecution(iUserID, iComment)
                # Nothing to do
                yield
              end

              # Check the last ping
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iComment* (_String_): The Ping comment
              def checkData(iUserID, iComment)
                # Nothing to test
              end

            end

          end

        end

      end

    end

  end

end
