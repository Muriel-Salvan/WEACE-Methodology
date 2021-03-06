#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Methods used in Mediawiki testing

module WEACE

  module Test

    module Slave

      module Adapters

        module Mediawiki

          module Common

            # Get the Product's configuration to give the plugin for testing
            #
            # Return::
            # * <em>map<Symbol,Object></em>: The Product configuration
            def getProductConfig
              return {
                :MediawikiDir => '/path/to/Mediawiki'
              }
            end

          end

        end

      end

    end

  end

end
