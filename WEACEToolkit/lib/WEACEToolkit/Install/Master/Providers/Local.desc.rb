#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
#   * :Title (_String_): Name of the plugin
#   * :Description (_String_): Quick description
#   * :VarOptions (<em>list< [Symbol,list<Object> ]></em>): List of variables bound to parameters on command line options
{
  :Description => 'The local environment specifics for WEACE Master Server/Adapters. This is the simplest environment.',
  :Author => 'muriel@x-aeon.com',
  :VarOptions => [
    [
      :ShellDir,
      '-d', '--shelldir <Directory>', String,
      '<Directory>: Directory where the WEACE Toolkit will generate Shell scripts.',
      'Example: /home/WEACETools'
    ]
  ],
  :OptionsExample => '--shelldir /home/WEACETools'
}
