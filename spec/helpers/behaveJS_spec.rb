require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BehaveJSActionView do
  
  context "behaveJS" do
    
    context "link_to" do

      # link to with block not supported until Rails 2
      if Rails::VERSION::STRING > "2.2.2"
        it "should accept a block for content" do
          result = helper.link_to("#", :config => { :attr1 => 1, :attr2 => false }) { "Content" }
          result.should have_tag("a", :text => "Content")
          result.should have_tag("a[data-attr1=1]")
          result.should have_tag("a[data-attr2=false]")
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
      
      it "should convert :config arguments into attributes" do
        result = helper.link_to("Link", "#", :config => { :attr1 => true, :attr2 => 100, :attr3 => false })
        result.should have_tag("a[data-attr1=true]")
        result.should have_tag("a[data-attr2=100]")
        result.should have_tag("a[data-attr3=false]")
      end
      
      it "should convert behaviors into an attribute" do
        result = helper.link_to("Link", "#", :behaves => { :click => :make_blue, :mouseover => :makered, :mouseout => :makeyellow })
        # though data-behaves is one string, we can't verify the ordering of the behaviors as it is an unordered hash,
        # so we make sure that a single behavior string exists in the attribute using "*="
        result.should have_tag("a[data-behaves*=click:make_blue]")
        result.should have_tag("a[data-behaves*=mouseover:makered]")
        result.should have_tag("a[data-behaves*=mouseout:makeyellow]")
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
        
        result = helper.link_to("Link", "#", :confirm => "Really?", :behaves => { :click => :go })
        result.should_not have_tag("a[data-behaves=click:default]")
        result.should have_tag("a[data-behaves=click:go]")
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
      
      it "should accept config/behavior attributes" do
        # test with block and without
        options = { :class => "cool", :config => { :attr1 => 10, :attr2 => false, :attr3 => true }, :behaves => { :click => :makeblue } }
        
        if Rails::VERSION::STRING > "2.1.2"
          result1 = helper.content_tag(:div, options) { "Content" }
        else
          # can't seem to pass instance variables into erb, so using #inspect
          result1 = eval_erb(%{<% content_tag("div", #{options.inspect}) do %>Content<% end %>})
        end
          
        result2 = helper.content_tag(:div, "Content", options)

        [ result1, result2].each do |result|
          result.should have_tag("div.cool", :text => "Content")
          result.should have_tag("div[data-attr1=10]")
          result.should have_tag("div[data-attr2=false]")
          result.should have_tag("div[data-attr3=true]")
          result.should have_tag("div[data-behaves=click:makeblue]")
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
  
      it "should convert config arguments into attributes" do
        result = eval_erb(%{<% form_tag("/", :config => { :attr1 => true, :attr2 => 100, :attr3 => false }) do %>Some Text<% end %>})
        result.should have_tag("form[data-attr1=true]")
        result.should have_tag("form[data-attr2=100]")
        result.should have_tag("form[data-attr3=false]")
      end
       
      it "should convert behaviors into an attribute" do
        result = eval_erb(%{<% form_tag("/", :behaves => { :click => :make_blue, :mouseover => :makered, :mouseout => :makeyellow }) do %>Some Text<% end %>})
        # though data-behaves is one string, we can't verify the ordering of the behaviors as it is an unordered hash,
        # so we make sure that a single behavior string exists in the attribute using "*="
        result.should have_tag("form[data-behaves*=click:make_blue]")
        result.should have_tag("form[data-behaves*=mouseover:makered]")
        result.should have_tag("form[data-behaves*=mouseout:makeyellow]")
      end
      
      it "should not set a data-method attribute" do
        result = eval_erb(%{<% form_tag("/", :method => :put) do %>Some Text<% end %>})
        result.should_not have_tag("form[data-method]")
      end
      
      it "should set the submit behavior to default when required" do
        # confirm was not specified, we should not be using the "default" submit behavior
        result = eval_erb(%{<% form_tag("/", :method => :put) do %>Some Text<% end %>})
        result.should_not have_tag("form[data-behaves=submit:default]")
        
        # no submit behavior was specified and confirm is provided, use "default" submit behavior
        result = eval_erb(%{<% form_tag("/", :method => :put, :confirm => "Really?") do %>Some Text<% end %>})
        result.should have_tag("form[data-behaves=submit:default]")
        
        # the "go" submit behavior was specified, so it should be used
        result = eval_erb(%{<% form_tag("/", :method => :put, :confirm => "Really?", :behaves => { :submit => :go }) do %>Some Text<% end %>})
        result.should_not have_tag("form[data-behaves=submit:default]")
        result.should have_tag("form[data-behaves=submit:go]")  
      end

    end
  end

end  
