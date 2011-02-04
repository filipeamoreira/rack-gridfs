require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

require 'rack/builder'
require 'rack/mock'
require 'rack/test'

require 'mongo'
require File.join(File.dirname(__FILE__), '..', 'lib', 'rack', 'gridfs')


class Hash
  def except(*keys)
    rejected = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    reject { |key,| rejected.include?(key) }
  end
end

module Rack
  class GridFS
    module Test
      module Methods

        def stub_mongodb_connection
          Rack::GridFS::Endpoint.any_instance.stubs(:connect!).returns(true)
        end

        def test_database_options
          { :hostname => 'localhost', :port => 27017, :database => 'test', :prefix => 'gridfs' }
        end

        def db
          @db ||= Mongo::Connection.new(test_database_options[:hostname], test_database_options[:port]).db(test_database_options[:database])
        end

        def setup_app(opts={})
          gridfs_opts = test_database_options.merge(opts)

          Rack::Builder.new do
            use Rack::GridFS, gridfs_opts
            run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
          end
        end

        def load_artifact(filename, content_type, path=nil)
          contents = ::File.read(::File.join(::File.dirname(__FILE__), 'artifacts', filename))
          if path
            grid = Mongo::GridFileSystem.new(db)
            file = [path, filename].join('/')
            grid.open(file, 'w') { |f| f.write contents }
            grid.open(file, 'r')
          else      
            Mongo::Grid.new(db).put(contents, :filename => filename, :content_type => content_type)
          end
        end

      end
    end
  end
end