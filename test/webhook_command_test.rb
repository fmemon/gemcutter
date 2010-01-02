require 'command_helper'

class WebhookCommandTest < CommandTest
  context "webhooking" do
    setup do
      @gem = "foo"
      @api = "https://gemcutter.org/api/v1/web_hooks"
      @url = "http://example.com/hook"
      @command = Gem::Commands::WebhookCommand.new
      stub(@command).say
    end

    %w[-a --add -r --remove -f --fire].each do |option|
      should "raise an error with no URL with #{option}" do
        assert_raise OptionParser::MissingArgument do
          @command.handle_options([@gem, option])
        end
      end
    end

    context "adding a hook" do
      setup do
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:post, @api).to_return(:body => "Success!")

        @command.handle_options([@gem, "-a", @url])
        @command.execute
      end

      should "say hook was added" do
        assert_received(@command) do |command|
          command.say("Adding webhook...")
          command.say("Success!")
        end
      end

      should "post to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:post, @api,
                         :times => 1)
        assert_requested(:post, @api,
                         :headers => { 'Authorization' => 'key' })
      end
    end

    context "listing hooks with some available" do
      setup do
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:get, @api).to_return :body => <<EOF
{
  "foo": [{"url":"http://foogemhook.com","failure_count":0}],
  "all gems":[{"url":"http://allgemshook.com","failure_count":0}]
}
EOF
        @command.handle_options([])
        @command.execute
      end

      should "list hooks" do
        assert_received(@command) do |command|
          command.say("all gems:")
          command.say("- http://allgemshook.com")
          command.say("foo:")
          command.say("- http://foogemhook.com")
        end
      end

      should "send get to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:get, @api,
                         :times => 1)
        assert_requested(:get, @api,
                         :headers => { 'Authorization' => 'key' })
      end
    end

    context "listing hooks with none available" do
      setup do
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:get, @api).to_return(:body => "{}")
        @command.handle_options([])
        @command.execute
      end

      should "list hooks" do
        assert_received(@command) do |command|
          command.say("You haven't added any webhooks yet.")
        end
      end
    end

    context "listing hooks with a json error" do
      setup do
        stub(@command).terminate_interaction
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:get, @api).to_return(:body => "fubar")
        @command.handle_options([])
        @command.execute
      end

      should "dump out with error message" do
        assert_received(@command) do |command|
          command.say("There was a problem parsing the data:")
          command.say(/unexpected token at 'fubar'/)
        end
      end

      should "terminate interaction" do
        assert_received(@command) do |command|
          command.terminate_interaction
        end
      end
    end

    context "removing hooks" do
      setup do
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:delete, "#{@api}/remove").to_return(:body => "Success!")

        @command.handle_options([@gem, "-r", @url])
        @command.execute
      end

      should "say hook was removed" do
        assert_received(@command) do |command|
          command.say("Removing webhook...")
          command.say("Success!")
        end
      end

      should "send delete to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:delete, "#{@api}/remove",
                         :times => 1)
        assert_requested(:delete, "#{@api}/remove",
                         :headers => { 'Authorization' => 'key' })
      end
    end

    context "test firing hooks" do
      setup do
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:post, "#{@api}/fire").to_return(:body => "Success!")

        @command.handle_options([@gem, "-f", @url])
        @command.execute
      end

      should "say hook was fired" do
        assert_received(@command) do |command|
          command.say("Test firing webhook...")
          command.say("Success!")
        end
      end

      should "send post to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:post, "#{@api}/fire",
                         :times => 1)
        assert_requested(:post, "#{@api}/fire",
                         :headers => { 'Authorization' => 'key' })
      end
    end
  end
end
