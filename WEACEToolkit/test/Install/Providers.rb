#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Providers

        include WEACE::Toolbox
        include WEACE::Test::Common

        # Test that the Provider effectively returns correct value
        def testProviderEnv
          initTestCase do
            require "WEACEToolkit/Install/#{@Type}/Providers/#{@ScriptID}"
            lProviderPlugin = eval("WEACEInstall::#{@Type}::Providers::#{@ScriptID}.new")

            # If there is a need to instantiate variables, do it now
            if (defined?(getVariablesToInstantiate))
              instantiateVars(lProviderPlugin, getVariablesToInstantiate)
            end

            lProviderEnv = lProviderPlugin.getProviderEnvironment
            assert(lProviderEnv.kind_of?(Hash))
            # Call specific checks
            checkEnvironment(lProviderEnv)
          end
        end

      end

    end

  end

end
