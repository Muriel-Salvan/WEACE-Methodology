#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
# ** :Title (_String_): Name of the plugin
# ** :Description (_String_): Quick description
# ** :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'The WEACE Slave Client.',
  :Author => 'murielsalvan@users.sourceforge.net',
  :VarOptions => [
    [
      :ProviderID,
      '-t', '--providertype <ProvType>', String,
      '<ProvType>: Type of provider where we install components.',
      'Use -- after to add options that are specific to each Provider. See below to get the list of possible Providers and their respective options.'
    ]
  ]
}
