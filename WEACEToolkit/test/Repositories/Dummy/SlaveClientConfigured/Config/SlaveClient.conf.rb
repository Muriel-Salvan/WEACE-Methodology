# Configuration file of SlaveClient.
# This file has been generated by WEACEInstall.rb on 2010-01-29 16:29:24.
# Parameters used for its generation: --
# Feel free to modify it to accomodate to your configuration.


{
  # Log file used
  # String
  # :LogFile => '/var/log/WEACESlaveClient.log',

  # List of WEACE Slave Adapters that can be used by WEACE Slave Client
  # map <
  #   <ProductName> => map <
  #     <ToolName> => list< <ActionName> >
  #   >
  # >
  :WEACESlaveAdapters => {
  # 'Redmine_01' => {
  #   'TicketTracker' => [
  #     'RejectDuplicate'
  #   ]
  # }
  },
  :PersonalizedAttribute => 'PersonalizedValue'
}
