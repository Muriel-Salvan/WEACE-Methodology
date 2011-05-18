#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Providers

          class SourceForge < ::Test::Unit::TestCase

            include WEACE::Test::Install::Providers

            # Get the variables to instantiate in the Provider plugin.
            # This method can not be implemented if useless.
            #
            # Return:
            # * <em>map<Symbol,Object></em>: Variables to instantiate
            def getVariablesToInstantiate
              return {
                :ProjectUnixName => 'myproject'
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
                  :CGI => {
                    :InternalDirectory => "/home/groups/m/my/myproject/cgi-bin",
                    :URL => "http://myproject.sourceforge.net/cgi-bin"
                  },
                  :Shell => {
                    :InternalDirectory => '/home/groups/m/my/myproject/WEACETools/Slave'
                  },
                  :PersistentDir => '/home/groups/m/my/myproject/persistent/WEACE'
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
