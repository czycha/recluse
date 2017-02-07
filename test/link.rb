require_relative '../lib/recluse/link.rb'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

describe Recluse::Link do
  describe 'when creating relative URL with parent' do
    it 'should join the parent and the relative URL' do
      Recluse::Link.new('./path2', 'https://example.com/path1')
                   .to_s
                   .must_equal('https://example.com/path2')
      Recluse::Link.new('path2', 'https://example.com/path1')
                   .to_s
                   .must_equal('https://example.com/path2')
      Recluse::Link.new('../path2/b', 'https://example.com/path1/a')
                   .to_s
                   .must_equal('https://example.com/path2/b')
      Recluse::Link.new('path', 'https://example.com/')
                   .to_s
                   .must_equal('https://example.com/path')
      Recluse::Link.new('page.html', 'https://example.com/index.html')
                   .to_s
                   .must_equal('https://example.com/page.html')
      Recluse::Link.new('./page.html', 'https://example.com/index.html')
                   .to_s
                   .must_equal('https://example.com/page.html')
      Recluse::Link.new('../path2/index.html', 'https://example.com/path1/index.html')
                   .to_s
                   .must_equal('https://example.com/path2/index.html')
      Recluse::Link.new('/path2/index.html', 'https://example.com/path1/index.html')
                   .to_s
                   .must_equal('https://example.com/path2/index.html')
    end
  end
  describe 'when creating absolute URL with parent' do
    it 'should just return the absolute URL' do
      Recluse::Link.new('https://different-example.com/', 'https://example.com/')
                   .to_s
                   .must_equal('https://different-example.com/')
    end
  end
  describe 'when creating relative URL without valid parent' do
    it 'should fail' do
      assert_raises Recluse::LinkError do
        Recluse::Link.new('/path', nil)
      end
    end
  end
  describe 'when matching globs' do
    it 'should handle wildcards' do
      Recluse::Link.new('https://example.com/path', :root)
                   .match?('*example.com*')
                   .must_equal(true)
    end
    it 'should handle exact matches' do
      Recluse::Link.new('https://example.com/path', :root)
                   .match?('https://example.com/path')
                   .must_equal(true)
    end
    it 'should handle numerous globs' do
      Recluse::Link.new('https://example.com/path', :root)
                   .match?([
                             'https://example.com',
                             'https://example.com/not-path',
                             'https://example.com/path',
                             'https://example.com/path/2'
                           ])
                   .must_equal(true)
      Recluse::Link.new('https://example.com/path', :root)
                   .match?([
                             'https://example.com',
                             'https://example.com/not-path',
                             'https://example.com/path/2'
                           ])
                   .must_equal(false)
    end
  end
  describe 'when checking if internal' do
    it 'should return true if root' do
      Recluse::Link.new('https://example.com/', :root)
                   .internal?([
                                Addressable::URI.parse('https://example.com/')
                              ])
                   .must_equal(true)
    end
    it 'should check if the scheme is the same' do
      example_root = Addressable::URI.parse 'https://example.com/'
      Recluse::Link.internal_to?(example_root, Addressable::URI.parse('http://example.com/path'))
                   .must_equal(false)
      Recluse::Link.internal_to?(example_root, Addressable::URI.parse('https://example.com/path'))
                   .must_equal(true)
    end
    it 'should not check if the scheme is the same if squashed' do
      examples = [
        Recluse::Link.new('https://example.com/', 'http://domain.co/'),
        Recluse::Link.new('http://example.com/', 'http://domain.co/')
      ]
      examples.each do |example_a|
        roots = [example_a.address]
        examples.each do |example_b|
          example_b.internal?(roots, scheme_squash: true)
                   .must_equal(true)
        end
      end
    end
    it 'should return true if internal' do
      Recluse::Link.new('https://example.com/path/', 'http://domain.co/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/')
                              ])
                   .must_equal(true)
      Recluse::Link.new('https://example.com/path/index.php', 'http://domain.co/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/path/')
                              ])
                   .must_equal(true)
      Recluse::Link.new('https://example.com/path/index.php', 'http://domain.co/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/index.php')
                              ])
                   .must_equal(true)
      Recluse::Link.new('https://example.com/other-file.php', 'http://domain.co/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/index.php')
                              ])
                   .must_equal(true)
      Recluse::Link.new('test.php', 'https://example.com/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/index.php')
                              ])
                   .must_equal(true)
      Recluse::Link.new('./2/', 'https://example.com/path/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/path/')
                              ])
                   .must_equal(true)
      Recluse::Link.new('../other-path/', 'https://example.com/path/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/path/')
                              ])
                   .must_equal(false)
      Recluse::Link.new('../path/2/', 'https://example.com/path/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/path/')
                              ])
                   .must_equal(true)
      Recluse::Link.new('https://example.com/', 'http://domain.co/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/path/')
                              ])
                   .must_equal(false)
      Recluse::Link.new('https://example.com/other-path/', 'http://domain.co/')
                   .internal?([
                                Addressable::URI.parse('https://example.com/path/')
                              ])
                   .must_equal(false)
    end
  end
  describe 'when checking if runnable' do
    it 'should only approve http or https schemed URLs' do
      Recluse::Link.new('https://example.com/', :root)
                   .run?([], [])
                   .must_equal(true)
      Recluse::Link.new('http://example.com/', :root)
                   .run?([], [])
                   .must_equal(true)
      Recluse::Link.new('file://example.com/', :root)
                   .run?([], [])
                   .must_equal(false)
    end
    it 'should fail when matched with the blacklist' do
      Recluse::Link.new('https://example.com/', :root)
                   .run?(['https://*'], [])
                   .must_equal(false)
    end
    it 'should pass when matched with the whitelist' do
      Recluse::Link.new('https://example.com/', :root)
                   .run?(['https://*'], ['https://example*'])
                   .must_equal(true)
    end
  end
end
