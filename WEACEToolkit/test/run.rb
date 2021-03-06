# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'test/unit'

# This path is then used to access repositories
$WEACETestBaseDir = File.expand_path(File.dirname(__FILE__))

require 'rUtilAnts/Logging'
# !!! If debug is activated, the testNoParameter tests will fail as they will have the --debug flag given to them.
RUtilAnts::Logging::install_logger_on_object(:lib_root_dir => File.expand_path("#{$WEACETestBaseDir}/.."), :bug_tracker_url => 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055', :debug_mode => false)

$LOAD_PATH << File.dirname(__FILE__)

# Requires defining frameworks
require 'Common'
require 'Install/Common'
require 'Install/Adapters'
require 'Install/IndividualComponent'
require 'Install/GenericComponent'
require 'Install/GenericComponentTestBody'
require 'Install/Master/MasterProcess'
require 'Install/Master/MasterProduct'
require 'Install/Slave/SlaveListener'
require 'Install/Slave/SlaveProduct'
require 'Install/Slave/SlaveTool'
require 'Install/Slave/SlaveAction'
require 'Install/Providers'
require 'Master/Common'
require 'Master/MasterSender'
require 'Slave/Common'
require 'Slave/GenericAdapters/Common'
require 'Slave/GenericAdapters/Ping'
require 'Slave/GenericAdapters/TicketTracker/AddCommitComment'
require 'Slave/GenericAdapters/TicketTracker/AddLinkToTask'
require 'Slave/GenericAdapters/TicketTracker/AddReleaseComment'
require 'Slave/GenericAdapters/TicketTracker/Ping'
require 'Slave/GenericAdapters/TicketTracker/RejectDuplicate'
require 'Slave/GenericAdapters/Wiki/AddCommitComment'
require 'Slave/GenericAdapters/Wiki/Ping'

# Requires defining generic test suites
require 'Install/Master/MasterProcesses'
require 'Install/Master/MasterProducts'
require 'Install/Slave/SlaveListeners'
require 'Install/Slave/SlaveProducts'
require 'Install/Slave/SlaveTools'
require 'Install/Slave/SlaveActions'

# Requires defining individual test suites
(
  Dir.glob("#{File.dirname(__FILE__)}/Install/Global/**/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Master/Server/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Master/Providers/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Master/Adapters/**/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Client/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Providers/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Listeners/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Adapters/**/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Master/Server/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Master/Server/Processes/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Master/Server/Senders/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Slave/Client/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Slave/Adapters/*/*/*.rb")
).each do |iFileName|
  require iFileName
end
