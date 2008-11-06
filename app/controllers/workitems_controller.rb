#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# . Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#require 'openwfe/representations'


class WorkitemsController < ApplicationController

  before_filter :login_required

  # GET /workitems
  #  or
  # GET /workitems?wfid=:wfid
  #  or
  # GET /workitems?q=:q || GET /workitems?query=:query
  #
  def index

    @wfid = params[:wfid]
    @query = params[:q] || params[:query]

    @workitems = if @wfid
      OpenWFE::Extras::Workitem.find_all_by_wfid(@wfid)
    elsif @query
      OpenWFE::Extras::Workitem.search(@query)
    else
      OpenWFE::Extras::Workitem.find(:all)
    end

    respond_to do |format|

      format.html
        # => app/views/workitems/index.html.erb

      format.json do
        render(
          :json => @workitems.collect { |wi| wi.to_owfe_workitem.to_h }.to_json)
      end

      format.xml { render(:text => 'xml') }
    end
  end

  # GET /workitems/:id/edit
  #
  def edit

    @workitem = OpenWFE::Extras::Workitem.find(params[:id])

    # only responds in HTML...
  end

  # GET /workitems/:id
  #
  def show

    @workitem = OpenWFE::Extras::Workitem.find(params[:id])

    respond_to do |format|
      format.html # => app/views/show.html.erb
      format.json { render :text => 'json' }
      format.xml { render :text => 'xml' }
    end
  end

  # PUT /workitems/:id
  #
  def update

    wi0 = OpenWFE::Extras::Workitem.find(params[:id])
    wi1 = parse_workitem

    #state1 = wi1.attributes.delete('_state')

    render :text => wi1.inspect
  end

  protected

    def authorized? (action=action_name, resource=nil)

      return false unless current_user

      return true if [ 'show', 'index' ].include?(action)

      current_user.is_admin?
    end

    def parse_workitem

      begin

        ct = request.content_type.to_s

        # TODO : deal with Atom[Pub]

        return OpenWFE::Xml::workitem_from_xml(request.body.read) \
          if ct.match(/xml$/)

        return OpenWFE::Json.workitem_from_json(request.body.read) \
          if ct.match(/json$/)

        #
        # then we have a form...

        #if definition_id = params[:definition_id]
        #  definition = Definition.find(definition_id)
        #  params[:definition_url] = definition.local_uri if definition
        #end
        #if attributes = params[:attributes]
        #  params[:attributes] = ActiveSupport::JSON::decode(attributes)
        #end

        OpenWFE::WorkItem.from_h(params)

      rescue Exception => e

        logger.warn "failed to parse workitem : #{e}"

        nil
      end
    end
end

