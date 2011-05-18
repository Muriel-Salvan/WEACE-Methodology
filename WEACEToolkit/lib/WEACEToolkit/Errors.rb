# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  # Exception thrown when we want to modify a missing file
  class MissingFileError < RuntimeError
  end

  # Exception thrown when we want to use a missing directory
  class MissingDirError < RuntimeError
  end

  # Exception raised when a variable is missing
  class MissingVariableError < RuntimeError
  end

  # Error issued when modifying a file fails
  class FileModificationError < RuntimeError
  end
  
end
