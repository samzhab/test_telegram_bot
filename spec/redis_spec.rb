# spec/redis_spec.rb
require 'spec_helper'
require 'webmock/rspec'

RSpec.describe 'Redis Integration' do
  let(:redis) { Redis.new }

  it 'can set and get a value' do
    key = 'test_key'
    value = 'Hello, Redis!'
    redis.set(key, value)
    expect(redis.get(key)).to eq(value)
  end
  
  it 'sets a key with an expiration' do
     redis.setex('temp_key', 10, 'temporary value')
    # Check if the key exists (expecting the count of existing keys, which should be 1)
    expect(redis.exists('temp_key')).to eq(1)
    sleep 11 # wait for the key to expire
    # Check again (expecting 0 since the key should no longer exist)
    expect(redis.exists('temp_key')).to eq(0)
  end
  
    it 'pushes and pops values from a list' do
    redis.rpush('my_list', 'one')
    redis.rpush('my_list', 'two')

    expect(redis.lpop('my_list')).to eq('one')
    expect(redis.lpop('my_list')).to eq('two')
  end
  
   it 'sets and retrieves fields from a hash' do
    redis.hset('my_hash', 'field1', 'value1')
    redis.hset('my_hash', 'field2', 'value2')

    expect(redis.hget('my_hash', 'field1')).to eq('value1')
    expect(redis.hget('my_hash', 'field2')).to eq('value2')
    expect(redis.hgetall('my_hash')).to eq({'field1' => 'value1', 'field2' => 'value2'})
  end
  
  it 'increments and decrements a value' do
    redis.set('counter', 0)
    3.times { redis.incr('counter') }
    expect(redis.get('counter').to_i).to eq(3)

    2.times { redis.decr('counter') }
    expect(redis.get('counter').to_i).to eq(1)
  end
  
  
end
