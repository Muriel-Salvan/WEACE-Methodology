# Configuration file of MasterServer.
# This file has been generated by WEACEInstall.rb on 2010-01-29 16:29:24.
# Parameters used for its generation: --
# Feel free to modify it to accomodate to your configuration.


{
  # Log file used
  # String
  # :log_file => '/var/log/WEACEMasterServer.log',

  # List of WEACE Slave Clients to contact
  # list <
  #   {
  #     :Type => <ClientType>,
  #     :Tools => list < <ToolName> >
  #   }
  # >
  :WEACESlaveClients => [
  #  {
  #    :Type => 'Local',
  #    :Tools => [
  #      Tools::Wiki,
  #      Tools::TicketTracker
  #    ]
  #  }
  ],
  :PersonalizedAttribute => 'PersonalizedValue'
}

