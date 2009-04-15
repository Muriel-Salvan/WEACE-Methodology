#!/usr/bin/env ruby
#
# Provide a way to call a method with its parameters directly from this script.
# This is intended to be used internally by some WEACE Toolkit scripts.
#
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'fileutils'

# Get WEACE base directory (in absolute form), and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir(File.dirname(__FILE__))
$WEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << $WEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  # Execute a function along with its parameters stored in a file
  #
  # Parameters:
  # * *iFileName* (_String_): The file containing info
  def executeEmbeddedFunction(iFileName)
    # Read the file
    lInfo = nil
    File.open(iFileName, 'r') do |iFile|
      lInfo = Marshal.load(iFile.read)
    end
    # Remove the file
    FileUtils.rm_f(iFileName)
    # 1. Set the load path
    lInfo.LoadPath.each do |iDir|
      if (!$LOAD_PATH.include?(iDir))
        $LOAD_PATH << iDir
      end
    end
    # 2. Require all given files
    lInfo.RequireFiles.each do |iRequireName|
      require iRequireName
    end
    # 3. Call the method on the object with all its parameters
    eval("lInfo.Object.#{lInfo.FunctionName}(*lInfo.Parameters)")
  end

end

# Get the file name containing the call details
if (ARGV.size == 1)
  WEACE::executeEmbeddedFunction(ARGV[0])
end
