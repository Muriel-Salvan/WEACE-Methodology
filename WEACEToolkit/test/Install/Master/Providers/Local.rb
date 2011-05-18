#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Providers

          class Local < ::Test::Unit::TestCase

            include WEACE::Test::Install::Providers

            # Get the variables to instantiate in the Provider plugin.
            # This method can not be implemented if useless.
            #
            # Return:
            # * <em>map<Symbol,Object></em>: Variables to instantiate
            def getVariablesToInstantiate
              return {
                :ShellDir => '/home/WEACETools'
              }
            end

            # Check the environment returned by the plugin.
            # Use normal assertions to check it.
            #
            # Parameters:
            # * *iProviderEnv* (<em>map<Symbol,Object></em>): The Provider environment to check.
            def checkEnvironment(iProviderEnv)
              assert_equal(
                {
                  :WEACEExecuteCmd => 'ruby -w WEACEExecute.rb',
                  :Shell => {
                    :InternalDirectory => '/home/WEACETools'
                  },
                  :PersistentDir => '/home/WEACETools'
                },
                iProviderEnv
              )
            end

          end

        end

      end

    end

  end

end
