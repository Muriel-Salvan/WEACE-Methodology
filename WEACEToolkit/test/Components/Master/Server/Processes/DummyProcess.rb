# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master
  
    class Server

      module Processes

        class DummyProcess

          # Process the script and get the actions to perform on WEACE Slave Clients
          #
          # Parameters:
          # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
          # * *iAdditionalParameters* (<em>list<String></em>): Additional parameters given that were not parsed by the options parser
          # Return:
          # * _Exception_: An error, or nil in case of success
          def processScript(ioSlaveActions, iAdditionalParameters)
            $Variables[:ProcessParameters] = iAdditionalParameters

            return nil
          end

          # Get the command line options for this Process
          #
          # Return:
          # * _OptionParser_: The corresponding options
          def getOptions
            return OptionParser.new
          end

        end

      end
    
    end

  end

end
