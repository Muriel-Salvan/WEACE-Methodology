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

        # Get the Provider ID corresponding to this test case
        #
        # Return:
        # * _String_: The Provider type (Master or Slave)
        # * _String_: The Provider ID
        def getProviderID
          rProviderType = nil
          rProviderID = nil

          lMatchData = self.class.name.match(/^WEACE::Test::Install::(.*)::Providers::(.*)$/)
          if (lMatchData == nil)
            logErr "Testing class (#{self.class.name}) is not of the form WEACE::Test::Install::{Master|Slave}::Providers::<ProviderID>"
            raise RuntimeError, "Testing class (#{self.class.name}) is not of the form WEACE::Test::Install::{Master|Slave}::Providers::<ProviderID>"
          else
            rProviderType, rProviderID = lMatchData[1..2]
          end

          return rProviderType, rProviderID
        end

        # Test that the Provider effectively returns correct value
        def testProviderEnv
          # Get the name of the Provider to test based on the class name
          lProviderType, lProviderID = getProviderID

          initTestCase do
            require "WEACEToolkit/Install/#{lProviderType}/Providers/#{lProviderID}"
            lProviderPlugin = eval("WEACEInstall::#{lProviderType}::Providers::#{lProviderID}.new")

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
