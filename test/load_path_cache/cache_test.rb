require 'test_helper'

module Bootsnap
  module LoadPathCache
    class CacheTest < MiniTest::Test
      def setup
        @dir1 = Dir.mktmpdir
        @dir2 = Dir.mktmpdir
        FileUtils.touch("#{@dir1}/a.rb")
        FileUtils.mkdir_p("#{@dir1}/foo/bar")
        FileUtils.touch("#{@dir2}/b.rb")
        FileUtils.touch("#{@dir1}/conflict.rb")
        FileUtils.touch("#{@dir2}/conflict.rb")
        FileUtils.touch("#{@dir1}/dl#{DLEXT}")
        FileUtils.touch("#{@dir1}/both.rb")
        FileUtils.touch("#{@dir1}/both#{DLEXT}")
      end

      def teardown
        FileUtils.rm_rf(@dir1)
        FileUtils.rm_rf(@dir2)
      end

      def test_simple
        cache = Cache.new(NullCache, [@dir1])
        assert_equal("#{@dir1}/a.rb", cache.find('a'))
        cache.push_paths(@dir2)
        assert_equal("#{@dir2}/b.rb", cache.find('b'))
      end

      def test_unshifted_paths_have_higher_precedence
        cache = Cache.new(NullCache, [@dir1])
        assert_equal("#{@dir1}/conflict.rb", cache.find('conflict'))
        cache.unshift_paths(@dir2)
        assert_equal("#{@dir2}/conflict.rb", cache.find('conflict'))
      end

      def test_pushed_paths_have_lower_precedence
        cache = Cache.new(NullCache, [@dir1])
        assert_equal("#{@dir1}/conflict.rb", cache.find('conflict'))
        cache.push_paths(@dir2)
        assert_equal("#{@dir1}/conflict.rb", cache.find('conflict'))
      end

      def test_directory_caching
        cache = Cache.new(NullCache, [@dir1])
        assert cache.has_dir?("foo")
        assert cache.has_dir?("foo/bar")
        refute cache.has_dir?("bar")
      end

      def test_extension_permutations
        cache = Cache.new(NullCache, [@dir1])
        assert_equal("#{@dir1}/dl#{DLEXT}", cache.find('dl'))
        assert_equal("#{@dir1}/dl#{DLEXT}", cache.find("dl#{DLEXT}"))
        assert_equal("#{@dir1}/both.rb", cache.find("both"))
        assert_equal("#{@dir1}/both.rb", cache.find("both.rb"))
        assert_equal("#{@dir1}/both#{DLEXT}", cache.find("both#{DLEXT}"))
      end

      def test_development_mode
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i

        # without development_mode, no refresh
        dev_no_cache = Cache.new(NullCache, [@dir1], development_mode: false)
        dev_yes_cache = Cache.new(NullCache, [@dir1], development_mode: true)

        FileUtils.touch("#{@dir1}/new.rb")

        dev_no_cache.stubs(:now).returns(time + 31)
        refute dev_no_cache.find('new')

        dev_yes_cache.stubs(:now).returns(time + 28)
        refute dev_yes_cache.find('new')
        dev_yes_cache.stubs(:now).returns(time + 31)
        assert dev_yes_cache.find('new')
      end
    end
  end
end
