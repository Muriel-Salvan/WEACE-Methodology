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

      module Adapters

        include WEACE::Test::Common
        include WEACE::Test::Install::Common

        # Execute the WEACEInstall script with some given parameters, and check its error.
        # This is used with the current Adapter being tested.
        #
        # Parmeters:
        # * *iParameters* (<em>list<String></em>): The parameters to give the Adapter's installer
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'MasterServerInstalled' or 'SlaveClientInstalled']
        # ** *:ProductRepository* (_String_): Name of the Product repository to use [optional = nil]
        # ** *:ContextVars* (<em>map<String,String></em>): Context variables to add [optional = nil]
        # * _CodeBlock_: The code called once the installer was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the installer, or nil in case of success
        def executeInstallAdapter(iParameters, iOptions = {}, &iCheckCode)
          initTestCase do
            # Parse options
            lExpectedError = iOptions[:Error]
            lRepositoryName = iOptions[:Repository]
            if (lRepositoryName == nil)
              # By default, make the main component installed, otherwise it will always fail with MasterServer/SlaveClient not being installed.
              if (@Type == 'Master')
                lRepositoryName = 'MasterServerInstalled'
              else
                lRepositoryName = 'SlaveClientInstalled'
              end
            end
            lProductRepositoryName = iOptions[:ProductRepository]
            if (iOptions[:ContextVars] != nil)
              @ContextVars.merge!(iOptions[:ContextVars])
            end

            lComponentName = "#{@Type}/Adapter/#{@ProductID}/#{@ToolID}/#{@ScriptID}"
            if (@InstallTest)
              logDebug "Running test for installation of #{lComponentName}: Test #{@TestName}"
            else
              logDebug "Running test for #{lComponentName}: Test #{@TestName}"
            end
            # Setup the Product repository
            setupRepository(lProductRepositoryName) do
              # Initialize the Installer
              initInstaller(
                :Repository => lRepositoryName,
                # Always add the Providers, as otherwise it can't retrieve the Provider's config.
                :AddRegressionMasterProviders => (@Type == 'Master'),
                :AddRegressionSlaveProviders => (@Type == 'Slave')
              ) do
                # Replace variables in the parameters
                lReplacedParameters = []
                iParameters.each do |iParam|
                  lReplacedParameters << replaceVars(iParam)
                end
                execInstaller([ '--install', "#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/#{@ScriptID}", '--' ] + lReplacedParameters,
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
