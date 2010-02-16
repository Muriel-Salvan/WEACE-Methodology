# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters
    
      module Redmine
      
        module Common

          include WEACE::Common
        
          # Create a new Ruby session to execute the executeSQL method in a new environment
          #
          # Parameters:
          # * *iRedmineDir* (_String_): The directory where Redmine is installed
          # * *iMySQLHost* (_String_): The name of the MySQL host
          # * *iDBName* (_String_): The name of the database of Redmine
          # * *iDBUser* (_String_): The name of the database user
          # * *iDBPassword* (_String_): The password of the database user
          # * *Parameters* (<em>list<String></em>): Additional parameters
          def execMySQLOtherSession(iRedmineDir, iMySQLHost, iDBName, iDBUser, iDBPassword, *iParameters)
            execCmdOtherSession(". #{iRedmineDir}/DBEnv.sh", self, 'execMySQL', iMySQLHost, iDBName, iDBUser, iDBPassword, *iParameters)
          end

          # Connect to Redmine's database
          #
          # Parameters:
          # * *CodeBlock*: The code to be called once connected
          # ** *ioSQL* (_Object_): The SQL connection object
          # ** Return:
          # ** _Exception_: An error, or nil in case of success
          # Return:
          # * _Exception_: An error, or nil in case of success
          def connectRedmine
            return beginMySQLTransaction(@ProductConfig[:DBHost], @ProductConfig[:DBName], @ProductConfig[:DBUser], @ProductConfig[:DBPassword]) do |ioSQL|
              next yield(ioSQL)
            end
          end

          # Get the User ID based on its name
          #
          # Parameters:
          # * *iSQL* (_Object_): The SQL connection
          # * *iUserName* (_String_): User name to look for
          # Return:
          # * _String_: Corresponding user ID
          def getUserID(iSQL, iUserName)
            rUserID = nil

            iSQL.query(
              "select id
               from users
               where
                 login = '#{iUserName}'").each do |iRow|
              rUserID = iRow[0]
            end
            # If the user does not exist, create it if it is Scripts_Validator or Scripts_Developer
            if (rUserID == nil)
              if ((iUserName == 'Scripts_Validator') or
                  (iUserName == 'Scripts_Developer'))
                rUserID = createUser(iSQL, iUserName)
              else
                logErr "User #{iUserName} is not allowed to perform operations."
                raise RuntimeError, "User #{iUserName} is not allowed to perform operations."
              end
            end

            return rUserID
          end

          # Get the Ticket ID based on its subject
          #
          # Parameters:
          # * *iSQL* (_Object_): The SQL connection
          # * *iSubject* (_String_): Subject to look for
          # Return:
          # * _String_: Corresponding Ticket ID
          def getTicketID(iSQL, iSubject)
            rTicketID = nil

            iSQL.query(
              "select id
               from issues
               where
                 subject = '#{iSubject}'").each do |iRow|
              rTicketID = iRow[0]
            end
            # If the Ticket does not exist, error
            if (rTicketID == nil)
              logErr 'Ticket WEACE_Toolkit_Log does not exist.'
              raise RuntimeError, 'Ticket WEACE_Toolkit_Log does not exist.'
            end

            return rTicketID
          end

          # Create a user, and get its ID back
          #
          # Parameters:
          # * *iSQL* (_Object_): The SQL connection
          # * *iUserName* (_String_): User name to look for
          # Return:
          # * _String_: Corresponding user ID
          def createUser(iSQL, iUserName)
            rUserID = nil
              
            iSQL.query(
              "insert
                 into users
                 ( login,
                   hashed_password,
                   firstname,
                   lastname,
                   mail,
                   mail_notification,
                   admin,
                   status,
                   language,
                   created_on,
                   updated_on)
                 values (
                   #{iUserName},
                   'd443f2ee6aa7c899023abb3f3fad2240000ed021',
                   '#{iUserName}',
                   '#{iUserName}',
                   '#{iUserName}',
                   0,
                   0,
                   1,
                   'en',
                   '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}',
                   '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
                 )")
            rUserID = iSQL.insert_id()
            
            return rUserID
          end

          # Log an operation in the adapted Product
          #
          # Parameters:
          # * *iUserID* (_String_): User ID initiating the log.
          # * *iProductName* (_String_): Product name to log
          # * *iProductID* (_String_): Product ID to log
          # * *iToolID* (_String_): Tool ID to log
          # * *iActionID* (_String_): Action ID to log
          # * *iError* (_Exception_): The error to log, can be nil in case of success
          # * *iParameters* (<em>list<String></em>): The parameters given to the operation
          # Return:
          # * _Exception_: An error, or nil if success
          def logProduct(iUserID, iProductName, iProductID, iToolID, iActionID, iError, iParameters)
            return beginMySQLTransaction(@ProductConfig[:DBHost], @ProductConfig[:DBName], @ProductConfig[:DBUser], @ProductConfig[:DBPassword]) do |ioSQL|
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
              next nil
            end
          end

        end
        
      end
      
    end
    
  end
  
end
