#!/usr/bin/env ruby
#
# Call a function of the WEACE Master/Server or Slave/Client functions.
# This is intended to be used internally by some WEACE Toolkit scripts.
#
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'optparse'

require 'fileutils'

module WEACE

  # Execute what has been given on the command line
  #
  # Parameters:
  # * *iParameters* (<em>list<String></em>): The command line parameters
  # Return:
  # * _Exception_: An error, or nil in case of success
  def self.execute(iParameters)
    rError = nil

    lComponent = nil
    if (iParameters.size > 1)
      case iParameters[0]
      when 'MasterServer'
        require 'WEACEToolkit/Master/Server/WEACEMasterServer'
        lComponent = WEACE::Master::Server.new
      when 'SlaveClient'
        require 'WEACEToolkit/Slave/Client/WEACESlaveClient'
        lComponent = WEACE::Slave::Client.new
      end
    end
    if (lComponent == nil)
      rError = RuntimeError.new('
Usage: WEACEExecute.rb <Component> <Arguments>
  <Component>: Either MasterServer or SlaveClient
  <Arguments>: Depend on the component on execute. Check http://weacemethod.sourceforge.net for details.

!!! This script is not intended to be run by the user directly. It is just here to provide an easy way for other WEACE Toolkit scripts to access WEACE Master Server and Slave Client.')
    else
      logInfo "Execution of #{iParameters[1..-1].join(' ')}"
      rError = lComponent.execute(iParameters[1..-1])
    end

    return rError
  end

end

# It is possible that we are required by the test framework
if (__FILE__ == $0)
  # Initialize logging
  require 'rUtilAnts/Logging'
  RUtilAnts::Logging::initializeLogging(File.expand_path("#{File.dirname(__FILE__)}/.."), 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
  require 'rUtilAnts/Platform'
  RUtilAnts::Platform::initializePlatform
  require 'rUtilAnts/Misc'
  RUtilAnts::Misc::initializeMisc
  lError = WEACE::execute(ARGV)
  if (lError == nil)
    exit 0
  else
    logErr "An error occurred: #{lError}."
    exit 1
  end
end
