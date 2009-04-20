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

  # Class encapsulating a Component's description
  class ComponentDescription
  
    include WEACE::Logging
  
    # The options
    #   OptionParser
    attr_accessor :Options
    
    # The description
    #   String
    attr_accessor :Description
    
    # The version
    #   String
    attr_accessor :Version
    
    # The author
    #   String
    attr_accessor :Author
    
    # Constructor
    #
    # Parameters:
    # * *iInstaller* (_Object_): Installer that will fill this description
    def initialize(iInstaller)
      @Installer = iInstaller
      @Options = OptionParser.new
      # map< Symbol, OptionParser >
      @MandatoryVariables = {}
    end
    
    # Add an option
    #
    # Parameters:
    # * *Parameters*: The parameters to give to OptionParser.on
    def addOption(*iParameters)
      @Options.on(*iParameters)
    end
    
    # Add an option linked to a variable
    #
    # Parameters:
    # * *iVariable* (_Symbol_): The variable to feed with this option argument
    # * *Parameters*: The parameters to give to OptionParser.on
    def addVarOption(iVariable, *iParameters)
      # Give access to iVariable
      @Installer.class.module_eval("
def getVar_#{iVariable}
  return @#{iVariable}
end
def setVar_#{iVariable}(iValue)
  @#{iVariable} = iValue
end
")
      @Options.on(*iParameters) do |iArg|
        eval("@Installer.setVar_#{iVariable}(iArg)")
      end
      # Create a little OptionParser to format the parameters correctly
      lSingleOption = OptionParser.new
      lSingleOption.on(*iParameters)
      @MandatoryVariables[iVariable] = lSingleOption
    end
    
    # Check that mandatory variables are affected
    def checkMandatoryVariables
      lFailure = false
      @MandatoryVariables.each do |iVariable, iOption|
        lValue = eval("@Installer.getVar_#{iVariable}")
        if (lValue == nil)
          logErr 'The following option is missing:'
          puts iOption.summarize
          lFailure = true
        end
      end
      if (lFailure)
        logExc RuntimeError, 'Some mandatory options were missing.'
      end
    end
    
  end
  
  module Common

    # Iterate through installed Adapters in the filesystem
    #
    # Parameters:
    # * *iDirectory* (_String_): The directory to parse for Adapters (Master/Slave)
    # * *CodeBlock*: The code to call for each directory found. Parameters:
    # ** *iProductID* (_String_): The product ID
    # ** *iToolID* (_String_): The tool ID
    # ** *iScriptID* (_String_): The script ID
    def eachAdapter(iDirectory)
      Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/*") do |iFileName1|
        if (File.directory?(iFileName1))
          lProductID = File.basename(iFileName1)
          Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/#{lProductID}/*") do |iFileName2|
            if (File.directory?(iFileName2))
              lToolID = File.basename(iFileName2)
              Dir.glob("#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/#{lProductID}/#{lToolID}/Install_*.rb") do |iFileName3|
                if (!File.directory?(iFileName3))
                  lScriptID = File.basename(iFileName3).match(/Install_(.*)\.rb/)[1]
                  yield(lProductID, lToolID, lScriptID)
                end
              end
            end
          end
        end
      end
    end

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
    
    # Get an installer from a given file
    #
    # Parameters:
    # * *iFileName* (_String_): The file name where the installer class is defined (relative to WEACE Toolkit base dir)
    # * *iClassName* (_String_): The class name
    # Return:
    # * _Object_: The installer
    def getInstallerFromFile(iFileName, iClassName)
      rInstaller = nil
      
      # Require the script
      begin
        require iFileName
        # Instantiate the installer
        begin
          rInstaller = eval("#{iClassName}.new")
        rescue Exception
          logErr "Error while getting installer from file #{iFileName}: #{$!}"
          logErr "Check that class #{iClassName} is correctly defined in it."
          logErr 'This file will be ignored.'
        end
      rescue Exception
        logErr "Error while requiring file #{iFileName}: #{$!}"
        logErr 'This file will be ignored.'
      end
      
      return rInstaller
    end
    
    # Initialize the options of an installer from a file, and return it
    #
    # Parameters:
    # * *iFileName* (_String_): The file name where the installer class is defined (relative to WEACE Toolkit base dir)
    # * *iClassName* (_String_): The class name
    # * *iParameters* (<em>list<String></em>): The list of parameters to give the installer
    # Return:
    # * _Object_: The installer, with its options parsed
    # * <em>list<String></em>: Additional arguments that were not part of the installers'
    def getInitializedInstallerFromFile(iFileName, iClassName, iParameters)
      # First, get the installer
      rInstaller = getInstallerFromFile(iFileName, iClassName)
      if (rInstaller == nil)
        logExc RuntimeError, "Could not get an installer from file #{iFileName}. Check that class #{iClassName} is correctly defined in it."
      end
      # Get the options
      lDescription = WEACEInstall::ComponentDescription.new(rInstaller)
      rInstaller.getDescription(lDescription)
      lOptions = lDescription.Options
      # Parse them
      lInstallerArgs, rAdditionalArgs = splitParameters(iParameters)
      begin
        lOptions.parse(lInstallerArgs)
      rescue
        logErr "Error while parsing arguments of the #{iClassName} installer: #{$!}"
        puts lOptions.summarize
        raise
      end
      # check mandatory variables
      lDescription.checkMandatoryVariables
      
      return rInstaller, rAdditionalArgs
    end
    
    # Get the description of a given component from a file
    #
    # Parameters:
    # * *iFileName* (_String_): The file name where the installer class is defined (relative to WEACE Toolkit base dir)
    # * *iClassName* (_String_): The class name
    # Return:
    # * _ComponentDescription_: The description, or nil in case of failure
    def getDescriptionFromFile(iFileName, iClassName)
      rDescription = nil
      
      # First, get the installer
      lInstaller = getInstallerFromFile(iFileName, iClassName)
      # Get options
      begin
        rDescription = WEACEInstall::ComponentDescription.new(lInstaller)
        lInstaller.getDescription(rDescription)
      rescue Exception
        logErr "Error while getting description from file #{iFileName}: #{$!}"
        logErr "Check that method #{iClassName}.getDescription is correctly defined in it."
        logErr 'This file will be ignored.'
        rDescription = nil
      end
      
      return rDescription
    end

  end

end
