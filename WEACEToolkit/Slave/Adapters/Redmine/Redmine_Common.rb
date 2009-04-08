# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module Redmine

  # Get the User ID based on its name
  #
  # Parameters:
  # * *iMySQLConnection* (_Mysql_): The MySQL connection
  # * *iUserName* (_String_): User name to look for
  # Return:
  # * _String_: Corresponding user ID
  def self.getUserID(iMySQLConnection, iUserName)
    rUserID = nil
    
    iMySQLConnection.query(
      "select id
       from users
       where
         login = '#{iUserName}'").each do |iRow|
      rUserID = iRow[0]
    end
    
    return rUserID
  end

end
