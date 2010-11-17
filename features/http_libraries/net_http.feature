Feature: Net::HTTP

  There are many ways to use Net::HTTP.  The scenarios below provide regression
  tests for some Net::HTTP APIs that have not worked properly with VCR and
  FakeWeb or WebMock in the past (but have since been fixed).

  Background:
    Given a file named "vcr_setup.rb" with:
      """
      require 'vcr_cucumber_helpers'

      if ARGV[0] == '--with-server'
        start_sinatra_app(:port => 7777) do
          get('/')  { 'VCR works with Net::HTTP gets!' }
          post('/') { 'VCR works with Net::HTTP posts!' }
        end
      end

      require 'vcr'
      """

  Scenario Outline: Calling #post on new Net::HTTP instance
    Given a file named "vcr_net_http.rb" with:
      """
      require 'vcr_setup.rb'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('net_http', :record => :new_episodes) do
        puts Net::HTTP.new('localhost', 7777).post('/', '').body
      end
      """
    When I run "ruby vcr_net_http.rb --with-server"
    Then the output should contain "VCR works with Net::HTTP posts!"
    And the file "cassettes/net_http.yml" should contain "body: VCR works with Net::HTTP posts!"

    When I run "ruby vcr_net_http.rb"
    Then the output should contain "VCR works with Net::HTTP posts!"

    Examples:
      | stub_with |
      | :fakeweb  |
      | :webmock  |

  Scenario Outline: Return from yielded block
    Given a file named "vcr_net_http.rb" with:
      """
      require 'vcr_setup.rb'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      def perform_request
        Net::HTTP.new('localhost', 7777).request(Net::HTTP::Get.new('/', {})) do |response|
          return response
        end
      end

      VCR.use_cassette('net_http', :record => :new_episodes) do
        puts perform_request.body
      end
      """
    When I run "ruby vcr_net_http.rb --with-server"
    Then the output should contain "VCR works with Net::HTTP gets!"
    And the file "cassettes/net_http.yml" should contain "body: VCR works with Net::HTTP gets!"

    When I run "ruby vcr_net_http.rb"
    Then the output should contain "VCR works with Net::HTTP gets!"

    Examples:
      | stub_with |
      | :fakeweb  |
      | :webmock  |

  Scenario Outline: Use Net::ReadAdapter to read body in fragments
    Given a file named "vcr_net_http.rb" with:
      """
      require 'vcr_setup.rb'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('net_http', :record => :new_episodes) do
        body = ''

        Net::HTTP.new('localhost', 7777).request_get('/') do |response|
          response.read_body { |frag| body << frag }
        end

        puts body
      end
      """
    When I run "ruby vcr_net_http.rb --with-server"
    Then the output should contain "VCR works with Net::HTTP gets!"
    And the file "cassettes/net_http.yml" should contain "body: VCR works with Net::HTTP gets!"

    When I run "ruby vcr_net_http.rb"
    Then the output should contain "VCR works with Net::HTTP gets!"

    Examples:
      | stub_with |
      | :fakeweb  |
      | :webmock  |

  Scenario Outline: Use open-uri (which is built on top of Net::HTTP and uses a seldom-used Net::HTTP API)
    Given a file named "vcr_net_http.rb" with:
      """
      require 'open-uri'
      require 'vcr_setup.rb'

      VCR.config do |c|
        c.stub_with <stub_with>
        c.cassette_library_dir = 'cassettes'
      end

      VCR.use_cassette('net_http', :record => :new_episodes) do
        puts open('http://localhost:7777/').read
      end
      """
    When I run "ruby vcr_net_http.rb --with-server"
    Then the output should contain "VCR works with Net::HTTP gets!"
    And the file "cassettes/net_http.yml" should contain "body: VCR works with Net::HTTP gets!"

    When I run "ruby vcr_net_http.rb"
    Then the output should contain "VCR works with Net::HTTP gets!"

    Examples:
      | stub_with |
      | :fakeweb  |
      | :webmock  |