begin
  # test using the spec helper provided by the application
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  # test using the default spec helper we provide
  require File.dirname(__FILE__) + "/default_spec_helper"
end