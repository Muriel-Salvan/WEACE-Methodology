#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# * <em>map<Symbol,Object></em>: Information on the plugin: the following symbols can be provided (additionnally to the standard ones provided by rUtilAnts):
#   * :Title (_String_): Name of the plugin
#   * :Description (_String_): Quick description
#   * :VarOptions (<em>list<[Symbol,list<Object>]></em>): List of variables bound to parameters on command line options
{
  :Description => 'This Slave Action is used for regression purposes only.',
  :Author => 'muriel@x-aeon.com',
  :VarOptions => WEACE::Test::Install::getGenericComponentVarOptions
}
