# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Common'

module WEACEInstall
  
  # Error while parsing command line arguments
  class CommandLineError < RuntimeError
  end

  # Error raised when we can't access a Provider
  class ProviderError < RuntimeError
  end

  module Common

    # Generate the WEACE environment file, used to load every environment parameter before executing or loading libraries from WEACE Toolkit
    def generateWEACEEnvFile
      # Find the rUtilAnts library directory
      lRUALibDir = nil
      if (defined?(Gem))
        # Look through Gems
        Gem.all_load_paths.each do |iGemLibDir|
          if (File.exists?("#{iGemLibDir}/rUtilAnts"))
            # So path to rUtilAnts is RubyGems' path
            $LOAD_PATH.each do |iDir|
              if (File.exists?("#{iDir}/rubygems.rb"))
                lRUALibDir = iDir
                break
              end
            end
            break
          end
        end
      end
      if (lRUALibDir == nil)
        # Look through normal load path
        $LOAD_PATH.each do |iDir|
          if (File.exists?("#{iDir}/rUtilAnts"))
            lRUALibDir = iDir
            break
          end
        end
      end
      if (lRUALibDir == nil)
        logBug 'Unable to find rUtilAnts library directory among Rubygems or $LOAD_PATH.'
      else
        File.open(@WEACEEnvFile, 'w') do |oFile|
          oFile << "\# This file is meant to be required by every script that needs to setup WEACE environment before loading and using WEACE Toolkit libraries.

\# Path containing rUtilAnts library (can be path to RubyGems)
$LOAD_PATH << '#{File.expand_path(lRUALibDir)}'
\# Path containing WEACE Toolkit library
$LOAD_PATH << '#{File.expand_path(File.dirname(@WEACELibDir))}'
"
        end
      end
    end

    # Get a Provider's environment
    #
    # Parameters:
    # * *iProviderType* (_String_): The Provider type (Master or Slave)
    # * *iProviderID* (_String_): The Provider ID
    # * *iParameters* (<em>list<String></em>): The parameters to give this provider
    # Return:
    # * _Exception_: An error, or nil in case of success
    # * <em>map<Symbol,Object></em>: The Provider's environment
    def getProviderEnv(iProviderType, iProviderID, iParameters)
      rError = nil
      rProviderConfig = nil

      logDebug "Read specific type #{iProviderID} configuration ..."
      lProviderPlugin, lError = @PluginsManager.getPluginInstance("#{iProviderType}/Providers", iProviderID)
      if (lError != nil)
        rError = ProviderError.new("Error while getting #{iProviderType} Provider named #{iProviderID}: #{lError}. Please use --list option to know available Providers.")
      else
        rError, lAdditionalArgs = initPluginWithParameters(lProviderPlugin, iParameters)
        if (rError == nil)
          # Get the environment from the provider
          rProviderConfig = lProviderPlugin.getProviderEnvironment
          # Complete the provider config with properties we can make use of.
          if (iProviderType == 'Master')
            if (rProviderConfig[:WEACEMasterInfoURL] == nil)
              # Set the URL for WEACEMasterInfo
              if ((rProviderConfig[:CGI] != nil) and
                  (rProviderConfig[:CGI][:URL] != nil))
                # If the Provider is able to give a CGI URL, use it to give explanations to the user.
                rProviderConfig[:WEACEMasterInfoURL] = rProviderConfig[:CGI][:URL]
              else
                # Otherwise, use a default WEACE URL
                rProviderConfig[:WEACEMasterInfoURL] = 'http://weacemethod.sourceforge.net'
              end
            end
          else
            if (rProviderConfig[:WEACESlaveInfoURL] == nil)
              # Set the URL for WEACESlaveInfo
              if ((rProviderConfig[:CGI] != nil) and
                  (rProviderConfig[:CGI][:URL] != nil))
                # If the Provider is able to give a CGI URL, use it to give explanations to the user.
                rProviderConfig[:WEACESlaveInfoURL] = rProviderConfig[:CGI][:URL]
              else
                # Otherwise, use a default WEACE URL
                rProviderConfig[:WEACESlaveInfoURL] = 'http://weacemethod.sourceforge.net'
              end
            end
          end
        end
      end

      return rError, rProviderConfig
    end

    # Check that mandatory variables are affected.
    # Raise an exception if they are not all affected.
    #
    # Parameters:
    # * *iVariablesSet* (<em>map<Symbol,[OptionsParser,String]></em>): The set of variables, along with their options
    # Return:
    # * _Exception_: An error, or nil in case of success
    def checkMandatoryVariables(iVariablesSet)
      rError = nil

      lMissingOptions = []
      iVariablesSet.each do |iVariable, iVariableInfo|
        iOption, iValue = iVariableInfo
        if (iValue == nil)
          lMissingOptions << iOption.summarize
        end
      end
      if (!lMissingOptions.empty?)
        rError = CommandLineError.new("The following options are missing:\n#{lMissingOptions.join("\n")}")
      end

      return rError
    end

    # Initialize a plugin instance with parameters taken from the command line if options were defined in the description.
    # It checks if mandatory parameters have been specified, and creates instance variables storing the corresponding values.
    #
    # Parameters:
    # * *ioPlugin* (_Object_): Plugin to initialize
    # * *iParameters* (<em>list<String></em>): Parameters to give to this plugin
    # * *iExtraParametersAllowed* (_Boolean_): Are extra parameters allowed ? If true, extra parameters will be returned back with a '--' separator. [optional = false]
    # Return:
    # * _Exception_: An error, or nil in case of success
    # * <em>list<String></em>: Remaining arguments
    def initPluginWithParameters(ioPlugin, iParameters, iExtraParametersAllowed = false)
      rError = nil
      rAdditionalArgs = []

      lOptions = ioPlugin.pluginDescription[:Options]
      if (lOptions == nil)
        if (iExtraParametersAllowed)
          rAdditionalArgs = iParameters
        else
          lInstallerArgs, rAdditionalArgs = splitParameters(iParameters)
        end
      else
        lInstallerArgs, rAdditionalArgs = splitParameters(iParameters)
        # Parse them
        begin
          lRemainingArgs = lOptions.parse(lInstallerArgs)
          if ((!lRemainingArgs.empty?) and
              (!iExtraParametersAllowed))
            rError = CommandLineError.new("Remaining unknown arguments: #{lRemainingArgs.join(', ')}")
          end
          if (iExtraParametersAllowed)
            rAdditionalArgs = lRemainingArgs + ['--'] + rAdditionalArgs
          end
        rescue
          rError = CommandLineError.new("Error while parsing arguments of the #{ioPlugin.pluginDescription[:PluginCategoryName]}/#{ioPlugin.pluginDescription[:PluginName]} installer: #{$!}.\n#{lOptions.summarize}.")
        end
        if (rError == nil)
          # Check mandatory variables
          rError = checkMandatoryVariables(ioPlugin.pluginDescription[:MandatoryVariables])
          if (rError == nil)
            # Set instance variables for each of the variables to be read
            ioPlugin.pluginDescription[:MandatoryVariables].each do |iName, iInfo|
              iOption, iValue = iInfo
              eval("ioPlugin.instance_variable_set(:@#{iName}, iValue)")
            end
          end
        end
      end

      return rError, rAdditionalArgs
    end

  end

end
