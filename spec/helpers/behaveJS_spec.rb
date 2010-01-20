require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

DEFAULT_CONFIG_ATTRS  = { :attr1 => true, :attr2 => 100, :attr3 => false }.freeze
DEFAULT_BEHAVES_ATTRS = { :click => :make_blue, :mouseover => :makered, :mouseout => :makeyellow }.freeze
DEFAULT_OPTIONS       = { :config => DEFAULT_CONFIG_ATTRS, :behaves => DEFAULT_BEHAVES_ATTRS }.freeze

def verify_config_attrs(tag_name, result, config)
  config.each { |k, v| result.should have_tag("#{tag_name}[data-#{k}=#{v}]") }
end

def verify_behaves_attr(tag_name, result, behaves)
  # though data-behaves is one string, we can't verify the ordering of the behaviors as it is an unordered hash,
  # so we make sure that a single behavior string exists in the attribute using "*="
  behaves.each { |k, v| result.should have_tag("#{tag_name}[data-behaves*=#{k}:#{v}]") }
end

describe BehaveJSActionView do
  
  context "behaveJS" do
    
    context "link_to" do
      # link to with block not supported until Rails 2.2.2
      if Rails::VERSION::STRING > "2.2.2"
        it "should accept a block for content" do
          opts   = { :config => { :attr1 => 1, :attr2 => false } }
          result = helper.link_to("#", opts) { "Content" }

          result.should have_tag("a", :text => "Content")
          verify_config_attrs("a", result, opts[:config])
        end
      end
      
      it "should correctly set the click behavior to remote" do
        result = helper.link_to("Link", "#", :remote => true)
        result.should have_tag("a[data-behaves=click:remote]")
      end
      
      it "should set the 'remoteAction' config attribute if the remote options provides one" do
        result = helper.link_to("Link", "#", :remote => "MyCoolRemoteAction")
        result.should have_tag("a[data-behaves=click:remote]")
        result.should have_tag("a[data-remoteAction=MyCoolRemoteAction]")
      end
      
      it "should convert config and behaves arguments into attributes" do
        opts = { :config => DEFAULT_CONFIG_ATTRS, :behaves => DEFAULT_BEHAVES_ATTRS }
        result = helper.link_to("Link", "#", opts)
        
        verify_config_attrs("a", result, opts[:config])
        verify_behaves_attr("a", result, opts[:behaves])
      end
      
      it "should set the data-method attribute" do
        result = helper.link_to("Link", "#", :method => :put)
        result.should have_tag("a[data-method=put]")
      end
      
      it "should default the http method to GET" do
        result = helper.link_to("Link", "#")
        result.should have_tag("a[data-method=get]")
      end
      
      it "should set the click behavior to default when required" do
        # when no click behavior is provided, we use the default behavior
        result = helper.link_to("Link", "#", :method => :put)
        result.should have_tag("a[data-behaves=click:default]")
        
        result = helper.link_to("Link", "#", :confirm => "Really?")
        result.should have_tag("a[data-behaves=click:default]")
        
        result = helper.link_to("Link", "#", :popup => true)
        result.should have_tag("a[data-behaves=click:default]")
        
        opts = { :behaves => DEFAULT_BEHAVES_ATTRS, :confirm => "Really?" }
        result = helper.link_to("Link", "#", opts)
        result.should_not have_tag("a[data-behaves=click:default]")
        verify_behaves_attr("a", result, opts[:behaves])
      end
      
      it "should convert :popup options and store them JSON in an attribute" do
        # we use the HTML::Selector here because different versions of Rails place different spacing in the output
        result = helper.link_to("Link", "#", :popup => :true)
        result.should have_tag("a[data-behaves=click:default]")
        result.should have_tag("a[data-method=get]")
        
        HTML::Selector.new('a').select(HTML::Document.new(result).root).first.attributes["data-popup"].gsub(" ", "").should == "[&quot;true&quot;]"
        
        result = helper.link_to("Link", "#", :popup => ["a", "b"])
        result.should have_tag("a[data-behaves=click:default]")
        result.should have_tag("a[data-method=get]")
        
        HTML::Selector.new('a').select(HTML::Document.new(result).root).first.attributes["data-popup"].gsub(" ", "").should == "[&quot;a&quot;,&quot;b&quot;]"
      end
    end
    
    context "content_tag" do
      
      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.content_tag(:div, "Content", :class => "cool")
        result.should == %{<div class="cool">Content</div>}
      end
      
      it "should accept a block for content" do
        if Rails::VERSION::STRING > "2.1.2"
          result = helper.content_tag(:div) { "Content" }
        else
          result = eval_erb(%{<% content_tag(:div) do %>Content<% end %>})
        end
        
        result.should == %{<div>Content</div>}
      end
      
      it "should convert config and behaves arguments into attributes" do
        # test with block and without
        opts = { :class => "cool" }.merge(:config => DEFAULT_CONFIG_ATTRS, :behaves => DEFAULT_BEHAVES_ATTRS)
        
        if Rails::VERSION::STRING > "2.1.2"
          result1 = helper.content_tag(:div, opts) { "Content" }
        else
          # can't seem to pass instance variables into erb, so using #inspect
          result1 = eval_erb(%{<% content_tag("div", #{opts.inspect}) do %>Content<% end %>})
        end
          
        result2 = helper.content_tag(:div, "Content", opts)

        [ result1, result2].each do |result|
          result.should have_tag("div.cool", :text => "Content")
          verify_behaves_attr("div", result, opts[:behaves])
          verify_config_attrs("div", result, opts[:config])
        end
      end 
      
    end
    
    context "form_tag" do
      
      it "should accept a block for content" do
        result = eval_erb(%{<% form_tag("/") do %>Some Text<% end %>})
        result.should have_tag("form", :text => "Some Text")
      end
      
      it "should correctly set the submit behavior to remote" do
        result = eval_erb(%{<% form_tag("/", :remote => true) do %>Some Text<% end %>}) 
        result.should have_tag("form[data-behaves=submit:remote]")
      end
      
      it "should set the 'remoteAction' config attribute if the remote options provides one" do
        result = eval_erb(%{<% form_tag("/", :remote => :MyCoolRemoteAction) do %>Some Text<% end %>}) 
        result.should have_tag("form[data-behaves=submit:remote]")
        result.should have_tag("form[data-remoteAction=MyCoolRemoteAction]")
      end
  
      it "should convert config and behaves arguments into attributes" do
        opts = { :config => DEFAULT_CONFIG_ATTRS, :behaves => DEFAULT_BEHAVES_ATTRS }
        result = eval_erb(%{<% form_tag("/", #{opts.inspect}) do %>Some Text<% end %>})
        
        verify_config_attrs("form", result, opts[:config])
        verify_behaves_attr("form", result, opts[:behaves])
      end
      
      it "should not set a data-method attribute" do
        result = eval_erb(%{<% form_tag("/", :method => :put) do %>Some Text<% end %>})
        result.should_not have_tag("form[data-method]")
      end
      
      it "should set the submit behavior to default when required" do
        # confirm was not specified, we should not be using the "default" submit behavior
        result = eval_erb(%{<% form_tag("/", :method => :put) do %>Some Text<% end %>})
        result.should_not have_tag("form[data-behaves*=submit:default]")
        
        # no submit behavior was specified and confirm is provided, use "default" submit behavior
        result = eval_erb(%{<% form_tag("/", :method => :put, :confirm => "Really?") do %>Some Text<% end %>})
        result.should have_tag("form[data-behaves*=submit:default]")
        
        # the "go" submit behavior was specified, so it should be used
        result = eval_erb(%{<% form_tag("/", :method => :put, :confirm => "Really?", :behaves => { :submit => :go }) do %>Some Text<% end %>})
        result.should_not have_tag("form[data-behaves*=submit:default]")
        result.should have_tag("form[data-behaves*=submit:go]")  
      end

    end
  
    context "tag" do
      
      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.tag(:input, { :type => 'text', :disabled => true }) 
        result.should == %{<input disabled="disabled" type="text" />}
      end
      
      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:type => 'text', :disabled => true)
        result = helper.tag(:input, opts)
        
        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end
      
    end

    context "select_tag" do
      city_option_tags = "<option>NYC</option><option>Paris</option><option>Rome</option>"
      
      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.select_tag("destination", city_option_tags, :disabled => true)
        result.should == %{<select disabled="disabled" id="destination" name="destination">#{city_option_tags}</select>}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:disabled => true)
        result = helper.select_tag("destination", city_option_tags, opts)
        
        verify_config_attrs("select", result, opts[:config])
        verify_behaves_attr("select", result, opts[:behaves])
      end
        
    end
    
    context "text_field_tag" do
      
      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.text_field_tag('ip', '0.0.0.0', :maxlength => 15, :size => 20, :class => "ip-input")
        result.should == %{<input class="ip-input" id="ip" maxlength="15" name="ip" size="20" type="text" value="0.0.0.0" />}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:maxlength => 15, :size => 20, :class => "ip-input")
        result = helper.text_field_tag("ip", "0.0.0.0", opts)

        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end
      
    end
    
    context "label_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.label_tag('name', nil, :class => 'small_label')
        result.should == %{<label class="small_label" for="name">Name</label>}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:class => 'small_label')
        result = helper.label_tag('name', nil, opts)

        verify_config_attrs("label", result, opts[:config])
        verify_behaves_attr("label", result, opts[:behaves])
      end

    end
    
    context "hidden_field_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.hidden_field_tag('token', 'VUBJKB23UIVI1UU1VOBVI@')
        result.should == %{<input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS
        result = helper.hidden_field_tag('token', 'VUBJKB23UIVI1UU1VOBVI@', opts)

        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end

    end
    
    context "file_field_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.file_field_tag('file', :accept => 'text/html', :class => 'upload', :value => 'index.html')
        result.should == %{<input accept="text/html" class="upload" id="file" name="file" type="file" value="index.html" />}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:accept => 'text/html', :class => 'upload', :value => 'index.html')
        result = helper.file_field_tag('file', opts)

        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end

    end
    
    context "password_field_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.password_field_tag('pin', '1234', :maxlength => 4, :size => 6, :class => "pin-input")
        result.should == %{<input class="pin-input" id="pin" maxlength="4" name="pin" size="6" type="password" value="1234" />}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:maxlength => 4, :size => 6, :class => "pin-input")
        result = helper.password_field_tag('pin', '1234', opts)

        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end

    end
    
    context "text_area_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.text_area_tag('description', "Description goes here.", :disabled => true)
        result.should == %{<textarea disabled="disabled" id="description" name="description">Description goes here.</textarea>}
      end

      it "should accept config/behavior attributes" do
        # text_area_tag modifies the original parameter passed in!
        opts   = DEFAULT_OPTIONS.merge(:disabled => true)
        opts2  = opts.dup
        result = helper.text_area_tag('description', "Description goes here.", opts)

        verify_config_attrs("textarea", result, opts2[:config])
        verify_behaves_attr("textarea", result, opts2[:behaves])
      end

    end
    
    context "check_box_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.check_box_tag('eula', 'accepted', true, :disabled => true)
        result.should == %{<input checked="checked" disabled="disabled" id="eula" name="eula" type="checkbox" value="accepted" />}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:disabled => true)
        result = helper.check_box_tag('eula', 'accepted', true, opts)

        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end

    end
    
    context "radio_button_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.radio_button_tag('color', "green", true, :class => "color_input")
        result.should == %{<input checked="checked" class="color_input" id="color_green" name="color" type="radio" value="green" />}
      end

      it "should accept config/behavior attributes" do
        opts   = DEFAULT_OPTIONS.merge(:class => "color_input")
        result = helper.radio_button_tag('color', "green", true, opts)

        verify_config_attrs("input", result, opts[:config])
        verify_behaves_attr("input", result, opts[:behaves])
      end

    end
    
    context "submit_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.submit_tag("Save edits", :disabled => true)
        result.should == %{<input disabled="disabled" name="commit" type="submit" value="Save edits" />}
      end

      it "should accept config/behavior attributes" do
        # submit_tag modifies the original parameter passed in!
        opts   = DEFAULT_OPTIONS.merge(:disabled => true)
        opts2  = opts.dup
        result = helper.submit_tag("Save edits", opts)
        
        verify_config_attrs("input", result, opts2[:config])
        verify_behaves_attr("input", result, opts2[:behaves])
      end

    end
    
    context "image_submit_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = helper.image_submit_tag("agree.png", :disabled => true, :class => "agree-disagree-button")
        result.should == %{<input class="agree-disagree-button" disabled="disabled" src="/images/agree.png" type="image" />}
      end

      it "should accept config/behavior attributes" do
        # image_submit_tag modifies the original parameter passed in!
        opts   = DEFAULT_OPTIONS.merge(:disabled => true, :class => "agree-disagree-button")
        opts2  = opts.dup
        result = helper.image_submit_tag("agree.png", opts)

        verify_config_attrs("input", result, opts2[:config])
        verify_behaves_attr("input", result, opts2[:behaves])
      end

    end
    
    context "field_set_tag" do

      it "should not add any attributes if the :config and :behaves options are not provided" do
        result = eval_erb(%{<% field_set_tag do %><p><%= text_field_tag 'name' %></p><% end %>})
        result.should == %{<fieldset><p><input id="name" name="name" type="text" /></p></fieldset>}
      end

      # field_set_tag only supports options after 2.1.2
      if Rails::VERSION::STRING > "2.1.2"
        
        it "should accept config/behavior attributes" do
          opts   = DEFAULT_OPTIONS.merge(:class => "format" )
          result = eval_erb(%{<% field_set_tag(nil, #{opts.inspect}) do %><p><%= text_field_tag 'name' %></p><% end %>})
        
          verify_config_attrs("fieldset", result, opts[:config])
          verify_behaves_attr("fieldset", result, opts[:behaves])
        end
        
      end
      
    end
    
  end

end  
