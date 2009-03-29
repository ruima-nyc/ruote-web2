#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


class ExpressionsController < ApplicationController

  before_filter :login_required

  def show
    find_expression
  end

  def destroy

    find_expression

    ruote_engine.cancel_expression(@expression)

    sleep 0.350

    @process = ruote_engine.process_status(params[:wfid])

    redirect_to(@process ? process_path(@process.wfid) : processes_path)
  end

  protected

  def authorized?
    #
    # only admins may see and edit expressions
    #
    current_user && current_user.is_admin?
  end

  def find_expression

    wfid = params[:wfid]
    expid = swapdots(params[:expid])

    @process = ruote_engine.process_status(params[:wfid])

    @expression = @process.all_expressions.find { |fexp|
      fexp.fei.wfid == wfid &&
      fexp.fei.expid == expid &&
      (not fexp.is_a?(OpenWFE::Environment))
    }
  end

end
