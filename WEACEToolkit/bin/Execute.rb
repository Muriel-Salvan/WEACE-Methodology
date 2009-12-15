#!env ruby
#
# Provide a way to call a method with its parameters directly from this script.
# This is intended to be used internally by some WEACE Toolkit scripts.
#
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'fileutils'

require 'WEACEToolkit/WEACE_Common'

module WEACE

  # Execute a function along with its parameters stored in a file
  #
  # Parameters:
  # * *iFileName* (_String_): The file containing info
  def self.executeEmbeddedFunction(iFileName)
    # Read the file
    lInfo = nil
    File.open(iFileName, 'r') do |iFile|
      lInfo = Marshal.load(iFile.read)
    end
    # Remove the file
    FileUtils.rm_f(iFileName)
    # 1. Set the log file
    setLogFile(lInfo.LogFile)
    # 2. Set the load path
    lInfo.LoadPath.each do |iDir|
      if (!$LOAD_PATH.include?(iDir))
        $LOAD_PATH << iDir
      end
    end
    # 3. Require all given files
    lInfo.RequireFiles.each do |iRequireName|
      require iRequireName
    end
    # 4. Unserialize the method details
    lMethodDetails = Marshal.load(lInfo.SerializedMethodDetails)
    # 5. Call the method on the object with all its parameters
    eval("lMethodDetails.Object.#{lMethodDetails.FunctionName}(*lMethodDetails.Parameters)")
  end

end

# Get the file name containing the call details
if (ARGV.size == 1)
  WEACE::executeEmbeddedFunction(ARGV[0])
end