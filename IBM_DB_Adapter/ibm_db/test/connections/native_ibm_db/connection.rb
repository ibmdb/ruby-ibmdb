=begin
print "Using native IBM_DB\n"
require_dependency 'models/course'
require 'logger'

ActiveRecord::Base.logger = Logger.new STDOUT
ActiveRecord::Base.logger.level = Logger::FATAL

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter       => 'ibm_db',
    :username      => 'db2user',
    :password      => 'secret', 
    :host          => 'bilbao',
    :port          => '50000',
    :schema        => 'rails123',
    :account       => 'tester',
    :app_user      => 'tester_11',
    :application   => 'rails_tests',
    :workstation   => 'auckland',
    :start_id      => 100,
    :database      => 'ARUNIT',
    :parameterized => false
  },
  'arunit2' => {
    :adapter       => 'ibm_db',
    :username      => 'db2user',
    :password      => 'secret',
    :host          => 'bilbao',
    :port          => '50000',
    :schema        => 'rails123',
    :account       => 'tester',
    :app_user      => 'tester_11',
    :application   => 'rails_tests',
    :workstation   => 'auckland',
    :start_id      => 100,
    :database      => 'ARUNIT2',
    :parameterized => false
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
=end