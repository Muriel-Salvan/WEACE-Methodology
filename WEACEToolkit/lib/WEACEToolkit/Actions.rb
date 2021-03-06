# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  # Actions enumeration
  module Actions
    # For All:
    All_Ping = 'Ping'
    # For the Tickets Manager:
    Ticket_AddCommitComment = 'AddCommitComment'
    Ticket_AddReleaseComment = 'AddReleaseComment'
    Ticket_AddLinkToTask = 'AddLinkToTask'
    Ticket_RejectDuplicate = 'RejectDuplicate'
    # For the Project Manager:
    Task_AddLinkToTicket = 'AddLinkToTicket'
    Task_AddCommitComment = 'AddCommitComment'
    Task_AddReleaseComment = 'AddReleaseComment'
    # For the Wiki:
    Wiki_AddCommitComment = 'AddCommitComment'
    Wiki_AddReleaseComment = 'AddReleaseComment'
    # For the Files Manager:
    File_Upload = 'Upload'
    File_UploadReleaseNote = 'UploadReleaseNote'
  end

end
