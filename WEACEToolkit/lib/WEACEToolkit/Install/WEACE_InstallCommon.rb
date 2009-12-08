# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/WEACE_Common'

module WEACEInstall
  
  module Common

    # Split parameters, before and after the first -- encountered
    #
    # Parameters:
    # * *iParameters* (<em>list<String></em>): The parameters
    # Return:
    # * <em>list<String></em>: The first part
    # * <em>list<String></em>: The second part
    def splitParameters(iParameters)
      rFirstPart = iParameters
      rSecondPart = []
      
      lIdxSeparator = iParameters.index('--')
      if (lIdxSeparator != nil)
        if (lIdxSeparator == 0)
          rFirstPart = []
        else
          rFirstPart = iParameters[0..lIdxSeparator-1]
        end
        if (lIdxSeparator == iParameters.size-1)
          rSecondPart = []
        else
          rSecondPart = iParameters[lIdxSeparator+1..-1]
        end
      end

      return rFirstPart, rSecondPart
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
    # Return:
    # * _Exception_: An error, or nil in case of success
    # * <em>list<String></em>: Remaining arguments
    def initPluginWithParameters(ioPlugin, iParameters)
      rError = nil
      rAdditionalArgs = []

      lOptions = ioPlugin.pluginDescription[:Options]
      if (lOptions != nil)
        # Parse them
        lInstallerArgs, rAdditionalArgs = splitParameters(iParameters)
        begin
          lRemainingArgs = lOptions.parse(lInstallerArgs)
          if (!lRemainingArgs.empty?)
            rError = CommandLineError.new("Remaining unknown arguments: #{lRemainingArgs.join(', ')}")
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
