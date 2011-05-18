#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Providers

        include WEACE::Common
        include WEACE::Test::Common

        # Test that the Provider effectively returns correct value
        def testProviderEnv
          initTestCase do
            require "WEACEToolkit/Install/#{@Type}/Providers/#{@ProductID}"
            lProviderPlugin = eval("WEACEInstall::#{@Type}::Providers::#{@ProductID}.new")

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
