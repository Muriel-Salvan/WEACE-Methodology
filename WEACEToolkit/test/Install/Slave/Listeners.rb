# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  # This module contains every tool needed for test cases
  module Test

    module Install

      module Slave

        module Listeners

          include WEACE::Test::Common
          include WEACE::Test::Install::Common

          # Execute the WEACEInstall script with some given parameters, and check its error.
          # This is used with the current Listener being tested.
          #
          # Parmeters:
          # * *iParameters* (<em>list<String></em>): The parameters to give the Listener's installer
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
          # ** *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
          # ** *:Repository* (_String_): Name of the repository to be used [optional = 'SlaveClientInstalled']
          # ** *:ProductRepository* (_String_): Name of the Product repository to use [optional = nil]
          # * _CodeBlock_: The code called once the installer was run: [optional = nil]
          # ** *iError* (_Exception_): The error returned by the installer, or nil in case of success
          def executeInstallListener(iParameters, iOptions = {}, &iCheckCode)
            # Parse options
            lExpectedError = iOptions[:Error]
            lRepositoryName = iOptions[:Repository]
            if (lRepositoryName == nil)
              # By default, make the SlaveClient installed, otherwise it will always fail
              lRepositoryName = 'SlaveClientInstalled'
            end
            lProductRepositoryName = iOptions[:ProductRepository]

            initTestCase do
              # Setup the Product repository
              setupRepository(lProductRepositoryName) do
                # Initialize the Installer
                initInstaller(
                  :Repository => lRepositoryName,
                  # Always add the Providers, as otherwise it can't retrieve the Provider's config.
                  :AddRegressionSlaveProviders => true
                ) do
                  # Replace variables in the parameters
                  lReplacedParameters = []
                  iParameters.each do |iParam|
                    lReplacedParameters << replaceVars(iParam)
                  end
                  execInstaller([ '--install', "Slave/Listeners/#{@ScriptID}", '--' ] + lReplacedParameters,
                    :Error => lExpectedError
                  ) do |iError|
                    if (iCheckCode != nil)
                      iCheckCode.call(iError)
                    end
                  end
                end
              end
            end
          end

        end

      end

    end

  end

end
