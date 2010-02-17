#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'Redmine adapted to WEACE Slave.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :RedmineDir,
      '-d', '--redminedir <RedmineDir>', String,
      '<RedmineDir>: Redmine\'s installation directory.',
      'Example: /home/groups/m/my/myproject/redmine'
    ],
    [
      :MySQLLibDir,
      '-m', '--mysql <MySQLLibPath>', String,
      '<MySQLLibPath>: Path to the directory containing the MySQL (C-Connector) library.',
      'Example: /home/groups/m/my/myproject/mysql/lib'
    ],
    [
      :GemHomeDir,
      '-g', '--gemhome <GemHomePath>', String,
      '<GemHomePath>: Path to the Gems installed by RubyGems.',
      'Example: /home/groups/m/my/myproject/rubygems/mygems'
    ],
    [
      :RubyGemsLibDir,
      '-l', '--rubygemslib <RubyGemsLibPath>', String,
      '<RubyGemsLibPath>: Path to the directory containing RubyGems\' library.',
      'Example: /home/groups/m/my/myproject/rubygems/lib'
    ]
  ],
  :OptionsExample => '--redminedir /home/redmine --mysql /home/groups/m/my/myproject/mysql/lib --gemhome /home/groups/m/my/myproject/rubygems/mygems --rubygemslib /home/groups/m/my/myproject/rubygems/lib'
}
