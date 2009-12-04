# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACE_Common.rb'

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
    def checkMandatoryVariables(iVariablesSet)
      lFailure = false
      iVariablesSet.each do |iVariable, iVariableInfo|
        iOption, iValue = iVariableInfo
        if (iValue == nil)
          logErr 'The following option is missing:'
          puts iOption.summarize
          lFailure = true
        end
      end
      if (lFailure)
        logErr 'Some mandatory options were missing.'
        raise RuntimeError, 'Some mandatory options were missing.'
      end
    end

    # Initialize a plugin instance with parameters taken from the command line if options were defined in the description.
    # It checks if mandatory parameters have been specified, and creates instance variables storing the corresponding values.
    #
    # Parameters:
    # * *ioPlugin* (_Object_): Plugin to initialize
    # * *iParameters* (<em>list<String></em>): Parameters to give to this plugin
    # Return:
    # * <em>list<String></em>: Remaining arguments
    def initPluginWithParameters(ioPlugin, iParameters)
      rAdditionalArgs = []

      lOptions = ioPlugin.pluginDescription[:Options]
      if (lOptions != nil)
        # Parse them
        lInstallerArgs, rAdditionalArgs = splitParameters(iParameters)
        begin
          lRemainingArgs = lOptions.parse(lInstallerArgs)
          if (!lRemainingArgs.empty?)
            raise RuntimeError, "Remaining unknown arguments: #{lRemainingArgs.join(', ')}"
          end
        rescue
          logErr "Error while parsing arguments of the #{ioPlugin.pluginDescription[:PluginCategoryName]}/#{ioPlugin.pluginDescription[:PluginName]} installer: #{$!}.\n#{lOptions.summarize}."
          raise
        end
        # Check mandatory variables
        checkMandatoryVariables(ioPlugin.pluginDescription[:MandatoryVariables])
        # Set instance variables for each of the variables to be read
        ioPlugin.pluginDescription[:MandatoryVariables].each do |iName, iInfo|
          iOption, iValue = iInfo
          eval("ioPlugin.instance_variable_set(:@#{iName}, iValue)")
        end
      end

      return rAdditionalArgs
    end

  end

end
