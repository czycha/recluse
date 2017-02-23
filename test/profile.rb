require_relative '../lib/recluse/profile.rb'
require_relative './assertions/must_match_array.rb'
require 'uri'
require 'net/http'
require 'pp'
require 'user_config'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

##
# Skip test unless local server is active
def server?
  response = Net::HTTP.get_response(URI.parse('http://localhost:9533/'))
  raise unless response.class == Net::HTTPOK
rescue
  skip 'Local server not detected'
end

describe Recluse::Profile do
  before do
    @name = [*('a'..'z'), *('0'..'9')].sample(8).join
    @profile = Recluse::Profile.new(
      @name,
      ['http://localhost:9533/'],
      'test@example.com',
      scheme_squash: true,
      internal_only: false,
      redirect: true
    )
    @uconf = UserConfig.new '.recluse'
  end

  after do
    @uconf.delete "#{@name}.yaml" if @uconf.exist?("#{@name}.yaml")
  end

  it 'save profile' do
    @profile.save
    fname = "#{@name}.yaml"
    options = @uconf[fname]
    options['name'].must_equal @profile.name
    options['roots'].must_match_array @profile.roots
    options['email'].must_equal @profile.email
    options['blacklist'].must_match_array @profile.blacklist
    options['whitelist'].must_match_array @profile.whitelist
    (!options['internal_only'].nil? && options['internal_only']).must_equal @profile.internal_only
    (!options['scheme_squash'].nil? && options['scheme_squash']).must_equal @profile.scheme_squash
  end

  it 'load profile' do
    @profile.save
    other = Recluse::Profile.load @name
    assert(other == @profile)
  end

  it 'assert' do
    server?
    expectations = {
      'http://localhost:9533/' => {
        'a.ext' => true,
        'div.howdy' => false
      },
      'http://localhost:9533/404.html' => nil,
      'http://localhost:9533/second.html' => {
        'a.ext' => true,
        'div.howdy' => true
      },
      'http://localhost:9533/second.html?page=1' => {
        'a.ext' => true,
        'div.howdy' => true
      },
      'http://localhost:9533/third/' => {
        'a.ext' => false,
        'div.howdy' => true
      },
      'http://localhost:9533/third/fourth.html' => {
        'a.ext' => false,
        'div.howdy' => true
      }
    }
    @profile.assert(['a.ext', 'div.howdy'], quiet: true)
    children = @profile.results.children
    children.keys
            .must_match_array(expectations.keys)
    expectations.each do |url, values|
      children[url][:value].must_equal(values)
    end
  end

  it 'find' do
    server?
    expectations = {
      'http://localhost:9533/' => [
        'http://localhost:9533/third/',
        'https://google.com/'
      ],
      'http://localhost:9533/404.html' => [],
      'http://localhost:9533/second.html' => [
        'http://localhost:9533/third/',
        'http://localhost:9533/third/',
        'https://google.com/'
      ],
      'http://localhost:9533/third/' => [
        'http://localhost:9533/third/fourth.html',
        'http://localhost:9533/third/'
      ],
      'http://localhost:9533/second.html?page=1' => [
        'http://localhost:9533/third/',
        'http://localhost:9533/third/',
        'https://google.com/'
      ],
      'http://localhost:9533/third/fourth.html' => []
    }
    @profile.find(['https://google.com/*', 'http://localhost:9533/third/*'], quiet: true)
    parents = @profile.results.parents
    parents.keys
           .must_match_array(expectations.keys)
    expectations.each do |url, links|
      parents[url].must_match_array(links)
    end
  end

  it 'status' do
    server?
    expectations = {
      'http://localhost:9533/' => {
        value: '200',
        parents: [
          :root,
          'http://localhost:9533/third/'
        ]
      },
      'http://localhost:9533/404.html' => {
        value: '404',
        parents: ['http://localhost:9533/']
      },
      'http://localhost:9533/second.html' => {
        value: '200',
        parents: [
          'http://localhost:9533/',
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html?page=1',
          'http://localhost:9533/second.html?page=1',
          'http://localhost:9533/third/'
        ]
      },
      'http://localhost:9533/third/' => {
        value: '200',
        parents: [
          'http://localhost:9533/',
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html?page=1',
          'http://localhost:9533/second.html?page=1',
          'http://localhost:9533/second.html',
          'http://localhost:9533/third/',
          'http://localhost:9533/third/fourth.html'
        ]
      },
      'https://google.com/' => {
        value: '200',
        parents: [
          'http://localhost:9533/',
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html?page=1'
        ]
      },
      'http://localhost:9533/second.html?page=1' => {
        value: '200',
        parents: [
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html?page=1',
          'http://localhost:9533/second.html?page=1'
        ]
      },
      'https://github.com/' => {
        value: '200',
        parents: [
          'http://localhost:9533/second.html',
          'http://localhost:9533/second.html?page=1'
        ]
      },
      'http://localhost:9533/third/fourth.html' => {
        value: '200',
        parents: [
          'http://localhost:9533/third/'
        ]
      }
    }
    @profile.status(quiet: true)
    children = @profile.results.children
    children.keys
            .must_match_array(expectations.keys)
    expectations.each do |url, expectation|
      children[url][:value].code
                           .must_equal(expectation[:value])
      children[url][:parents].must_match_array(expectation[:parents])
    end
  end
end
