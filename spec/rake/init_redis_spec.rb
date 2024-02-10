 
# spec/tasks/init_redis_spec.rb
require 'spec_helper'
require 'rake'

describe 'init_redis task' do
  it 'initializes Redis without errors' do
    expect { Rake::Task['data:init_redis'].invoke }.not_to raise_error
  end
end
