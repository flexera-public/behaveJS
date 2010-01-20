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

module BehaveJSActionView

  OVERRIDDEN_HELPER_METHODS = [ :link_to, :content_tag, :form_tag, :tag ]
  
  def extract_and_dup(options, key)
    val = options.delete(key)
    val ? val.dup : {}
  end
  
  module InstanceMethods
    
    def to_config_attributes(options = {})
      new_hash = {}
      options.each do |k,v|
        new_value = [ FalseClass, TrueClass ].include?(v.class) ? v.to_s : v
        new_hash["data-#{k}".to_sym] = new_value unless new_value.blank?
      end
      new_hash
    end

    def _construct_behavior_string(behavior = {})
      behavior.collect { |event, behavior_name| "#{event}:#{behavior_name}"}.join(";")
    end

    def link_to_with_behaveJS(*args, &block)
      if block_given?
        name         = capture(&block)
        url          = args[0] || {}
        html_options = args[1] ? args[1].dup : {}
      else
        name         = args[0]
        url          = args[1] || {}
        html_options = args[2] ? args[2].dup : {}
      end

      html_options.stringify_keys!
      
      config   = extract_and_dup(html_options, "config").stringify_keys
      behavior = extract_and_dup(html_options, "behaves").stringify_keys
      remote   = html_options.delete("remote")
      popup    = html_options.delete("popup")

      raise "You can't use :popup and :method in the same link" if html_options["method"] && popup

      popup = true if popup.is_a?(String)

      config["confirm"]      = html_options.delete("confirm")
      config["method"]       = (html_options.delete("method") || "get").to_s
      config["popup"]        = popup && Array(popup).to_json

      # when a string/symbol is provided for the remote argument, we make that into a "remoteAction" config attribute
      config["remoteAction"] = remote if remote.is_a?(String) || remote.is_a?(Symbol)

      # the remote argument takes precedence over any specified click behavior
      behavior["click"] = "remote" if remote

      if !behavior["click"] && (config["confirm"] || config["popup"] || config["method"] !~ /get/i)
        # when a click behavior is not provided and either a confirm, method, or popup are used - we set the click behavior to default
        behavior["click"] = "default"
      end

      config["behaves"] = _construct_behavior_string(behavior)

      html_options.merge!(to_config_attributes(config))

      link_to_without_behaveJS(name, url, html_options)
    end

    def content_tag_with_behaveJS(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
      if block_given?
        content = nil
        options = content_or_options_with_block.dup if content_or_options_with_block.is_a?(Hash)
      else
        content = content_or_options_with_block
        options = options.dup if options
      end
      
      if options
        options.stringify_keys!
        
        config   = extract_and_dup(options, "config").stringify_keys
        behavior = options.delete("behaves") || {}
      
        config["behaves"] = _construct_behavior_string(behavior)
      
        # merge in behavior and configuration attributes
        options.merge!(to_config_attributes(config))
      end
      
      content_tag_without_behaveJS(name, content, options, escape, &block)
    end

    def form_tag_with_behaveJS(url_for_options = {}, options = {}, *parameters_for_url, &block)
      options  = options.dup.stringify_keys
      config   = extract_and_dup(options, "config").stringify_keys
      behavior = extract_and_dup(options, "behaves").stringify_keys
      remote   = options.delete("remote")
      
      # when a string/symbol is provided for the remote argument, we make that into a "remoteAction" config attribute
      config["remoteAction"] = remote if remote.is_a?(String) || remote.is_a?(Symbol)
      config["confirm"]      = options.delete("confirm")
      
      # the remote argument takes precedence over any specified submit behavior
      behavior["submit"] = "remote" if remote
      
      # use "default" behavior
      behavior["submit"] = "default" if !behavior["submit"] && config["confirm"]
      
      config["behaves"] = _construct_behavior_string(behavior)
      
      options.merge!(to_config_attributes(config))
      
      form_tag_without_behaveJS(url_for_options, options, *parameters_for_url, &block)
    end
    
    def tag_with_behaveJS(name, options = nil, open = false, escape = true)
      if options
        options  = options.dup.stringify_keys        
        config   = extract_and_dup(options, "config").stringify_keys
        behavior = extract_and_dup(options, "behaves").stringify_keys

        config["behaves"] = _construct_behavior_string(behavior)

        # merge in behavior and configuration attributes
        options.merge!(to_config_attributes(config))
      end
      
      tag_without_behaveJS(name, options, open, escape)
    end
    
    def behaveJS_bootstrap()
      <<-EOF
        <script type="text/javascript" charset="utf-8">
          behaveJS.bootstrap(#{behaveJS_data.to_json});
        </script>
      EOF
    end
  end
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      OVERRIDDEN_HELPER_METHODS.each { |method_name| alias_method_chain(method_name, :behaveJS) }
    end
  end
end

ActionView::Base.send(:include, BehaveJSActionView)
