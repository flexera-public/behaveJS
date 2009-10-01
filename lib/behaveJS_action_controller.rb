# Copyright (c) 2009 RightScale, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# Author : Eugene Gimelberg

module BehaveJSActionController

  module InstanceMethods
    
    def behaveJS_data_initialize
      # behaveJS data is only used when rendering with a full layout, so nothing is to be done for XHR requests
      return if request.xhr?
      
      @behaveJS_data = { :controllerName => controller_name, :actionName => action_name }
    end
    
    def behaveJS_data
      # behaveJS data is only used when rendering with a full layout, so nothing is to be done for XHR requests
      return {} if request.xhr?
      
      @behaveJS_data
    end
    
    def render_remote(remote_action, options = {})
      json_data = ((block_given? && yield) || {}).update(:remoteAction => remote_action)
      render options.merge(:json => json_data)
    end
  end
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      before_filter :behaveJS_data_initialize
      helper_method :behaveJS_data
    end
  end
end

ActionController::Base.send(:include, BehaveJSActionController)
