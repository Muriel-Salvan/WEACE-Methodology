# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class IssueRelationsController < ApplicationController
  before_filter :find_project, :authorize
  
  def new
    @relation = IssueRelation.new(params[:relation])
    @relation.issue_from = @issue

    # === Changed by WEACE Master Adapter for Redmine/TicketTracker... ===
    if (request.post?)
      if (@relation.relation_type == IssueRelation::TYPE_DUPLICATES)
        # Call WEACE Master Server
        lCommand = "%{WEACEExecuteCmd} MasterServer --user Scripts_Validator --process Ticket_CloseDuplicate -- --masterticket #{@relation.issue_to_id} --slaveticket #{@issue.id} 2>&1"
        lOutput = `#{lCommand}`
        lErrorCode = $?
        if (lErrorCode != 0)
          @relation.save
          logger.error("Call to WEACE Master Server failed (error code #{lErrorCode}). Here is the command: #{lCommand}. Here is its output: #{lOutput}.")
          flash[:warning] = l('Error while calling WEACE Master Server. Please check logs to get further details. The action was still performed as if WEACE Master Server was not installed.')
        else
          flash[:notice] = l('WEACE Master Server processed request successfully.')
        end
        render :update do |page|
          page.redirect_to(:controller => 'issues', :action => 'show', :id => @issue)
        end
        return
      else
        @relation.save
      end
    end
    # === ... End of change ===
    respond_to do |format|
      format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
      format.js do
        render :update do |page|
          page.replace_html "relations", :partial => 'issues/relations'
          if @relation.errors.empty?
            page << "$('relation_delay').value = ''"
            page << "$('relation_issue_to_id').value = ''"
          end
        end
      end
    end
  end
  
  def destroy
    relation = IssueRelation.find(params[:id])
    if request.post? && @issue.relations.include?(relation)
      relation.destroy
      @issue.reload
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
      format.js { render(:update) {|page| page.replace_html "relations", :partial => 'issues/relations'} }
    end
  end
  
private
  def find_project
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
