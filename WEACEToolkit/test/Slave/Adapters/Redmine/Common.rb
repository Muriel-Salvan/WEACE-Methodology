#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Methods used in Mediawiki testing

module WEACE

  module Test

    module Slave

      module Adapters

        module Redmine

          module Common

            # Get the Product's configuration to give the plugin for testing
            #
            # Return:
            # * <em>map<Symbol,Object></em>: The Product configuration
            def getProductConfig
              return {
                :RedmineDir => '/path/to/Redmine',
                :DBHost => 'DBHost',
                :DBName => 'DBName',
                :DBUser => 'DBUser',
                :DBPassword => 'DBPassword',
              }
            end

          end

        end

      end

    end

  end

end
