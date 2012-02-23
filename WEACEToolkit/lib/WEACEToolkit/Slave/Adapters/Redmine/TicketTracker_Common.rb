# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Slave/Adapters/Redmine/Common'

module WEACE

  module Slave

    module Adapters
    
      module Redmine
      
        module TicketTracker_Common

          include WEACE::Slave::Adapters::Redmine::Common

          # Execute SQL to log into Redmine/TicketTracker
          class SQL_LogProduct_TicketTracker < SQL_Execute

            include WEACE::Slave::Adapters::Redmine::Common::MiscUtils

            # Log an operation in the adapted Product.
            # This is the internal method used once the DB connection is active
            #
            # Parameters::
            # * *ioSQL* (_Object_): The SQL connection
            # * *iUserID* (_String_): User ID initiating the log.
            # * *iProductName* (_String_): Product name to log
            # * *iProductID* (_String_): Product ID to log
            # * *iToolID* (_String_): Tool ID to log
            # * *iActionID* (_String_): Action ID to log
            # * *iError* (_Exception_): The error to log, can be nil in case of success
            # * *iParameters* (<em>list<String></em>): The parameters given to the operation
            # Return::
            # * _Exception_: An error, or nil if success
            def execute(ioSQL, iUserID, iProductName, iProductID, iToolID, iActionID, iError, iParameters)
              # Get the User ID
              lRedmineUserID = getUserID(ioSQL, 'WEACE_Logger')
              # Get the Ticket ID
              lWEACELogTicketID = getTicketID(ioSQL, 'WEACE_Toolkit_Log')
              # Insert a comment on the WEACE_Toolkit_Log ticket
              lNow = DateTime.now
              lStrError = nil
              if (iError == nil)
                lStrError = 'Success'
              else
                lStrError = "Error: #{iError.gsub(/'/,'\\\\\'')}"
              end
              ioSQL.query(
                "insert
                   into journals
                   ( journalized_id,
                     journalized_type,
                     user_id,
                     notes,
                     created_on )
                   values (
                     #{lWEACELogTicketID},
                     'Issue',
                     #{lRedmineUserID},
                     '[#{lNow.strftime('%Y-%m-%d %H:%M:%S')}] - #{iUserID}@#{iProductName} - #{iProductID}/#{iToolID}/#{iActionID} - #{iParameters.join(' ').gsub(/'/,'\\\\\'')} - #{lStrError}',
                     '#{lNow.strftime('%Y-%m-%d %H:%M:%S')}'
                   )")

              return nil
            end

          end

          # Log an operation in the adapted Product
          #
          # Parameters::
          # * *iUserID* (_String_): User ID initiating the log.
          # * *iProductName* (_String_): Product name to log
          # * *iProductID* (_String_): Product ID to log
          # * *iToolID* (_String_): Tool ID to log
          # * *iActionID* (_String_): Action ID to log
          # * *iError* (_Exception_): The error to log, can be nil in case of success
          # * *iParameters* (<em>list<String></em>): The parameters given to the operation
          # Return::
          # * _Exception_: An error, or nil if success
          def logProduct(iUserID, iProductName, iProductID, iToolID, iActionID, iError, iParameters)
            return executeRedmine(
              SQL_LogProduct_TicketTracker.new,
              [ iUserID, iProductName, iProductID, iToolID, iActionID, iError, iParameters ]
            )
          end

        end
        
      end
      
    end
    
  end
  
end
