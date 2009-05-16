require "rubygems"
require "ruby-debug"
require "contest"
require File.dirname(__FILE__) + "/../lib/ohm"

$redis = Redis.new(:port => 6381)
$redis.flush_db

class Event < Ohm::Model
  attribute :name
end

class User < Ohm::Model
  attribute :email
end

class TestRedis < Test::Unit::TestCase
  context "Finding an event" do
    setup do
      $redis["Event:1"] = true
      $redis["Event:1:name"] = "Concert"
    end

    should "return an instance of Event" do
      assert Event[1].kind_of?(Event)
      assert_equal 1, Event[1].id
      assert_equal "Concert", Event[1].name
    end
  end

  context "Finding a user" do
    setup do
      $redis["User:1"] = true
      $redis["User:1:email"] = "albert@example.com"
    end

    should "return an instance of User" do
      assert User[1].kind_of?(User)
      assert_equal 1, User[1].id
      assert_equal "albert@example.com", User[1].email
    end
  end

  context "Mutating" do
    setup do
      $redis["User:1"] = true
      $redis["User:1:email"] = "albert@example.com"

      @user = User[1]
    end

    should "change attributes" do
      @user.email = "maria@example.com"
      assert_equal "maria@example.com", @user.email
    end

    should "save attributes" do
      @user.email = "maria@example.com"
      @user.save

      @user.email = "maria@example.com"
      @user.save

      assert_equal "maria@example.com", User[1].email
    end
  end

  context "creating" do
    should "increment the ID" do
      event1 = Event.new
      event1.create

      event2 = Event.new
      event2.create

      assert_equal event1.id + 1, event2.id
    end
  end

  context "saving" do
    should "not save a new model" do
      assert_raise Ohm::Model::ModelIsNew do
        Event.new.save
      end
    end

    should "save if the model was previously created" do
      event = Event.new
      event.name = "Lorem ipsum"
      event.create

      event.name = "Lorem"
      event.save

      assert_equal "Lorem", Event[event.id].name
    end
  end

  context "Listing" do
    should "find all" do
      event1 = Event.new
      event1.name = "Ruby Meetup"
      event1.create

      event2 = Event.new
      event2.name = "Ruby Tuesday"
      event2.create

      all = Event.all

      assert all.detect {|e| e.name == "Ruby Meetup" }
      assert all.detect {|e| e.name == "Ruby Tuesday" }
    end
  end

  context "internals" do
    setup do
      event = Event.new
      event.name = "Ruby Tuesday"
      @id = event.create.id
    end

    should "load attributes lazily" do
      event = Event[@id]

      assert_nil event.send(:instance_variable_get, "@name")
      assert_equal "Ruby Tuesday", event.name
    end
  end
end
