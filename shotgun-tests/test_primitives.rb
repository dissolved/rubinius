require 'rubygems'
require 'test/unit'
require 'test/unit/show_code'
require 'shotgun-tests/helper'

unless File.exists?("code-cache")
  Dir.mkdir "code-cache"
end

class TestPrimitives < Test::Unit::TestCase

  include RubiniusHelper
  
  def test_add
    assert_equal "3", ol("1 + 2")
  end
  
  def test_sub
    assert_equal "5", ol("10 - 5")
  end
  
  def test_mul
    assert_equal "25", ol("5 * 5")
  end
  
  def test_equal
    assert_equal "true", ol("5 == 5")
    assert_equal "false", ol("5 == 6")
  end
    
  def test_compare
    assert_equal "-1", ol("3 <=> 4")
    assert_equal "0", ol("3 <=> 3")
    assert_equal "1", ol("4 <=> 3")
  end
  
  def test_at
    out = run_code <<-CODE
    tp = Tuple.new(5)
    tp.put 3, 88
    p tp.at(3)
    CODE
    
    assert_equal "88", out.strip
  end
  
  def test_put
    # test_at tests both.
  end
  
  def test_fields
    out = run_code <<-CODE
    tp = Tuple.new(5)
    p tp.fields
    CODE
    
    assert_equal "5", out.strip
  end
  
  def test_allocate
    out = rp <<-CODE
    ary = Array.allocate
    p(ary.fields == Array.instance_fields)
    p(ary.class)
    CODE
    
    assert_equal ["true", "Array"], out
  end
  
  def test_allocate_count
    out = rp <<-CODE
    tp = Tuple.new(99)
    p(tp.fields)
    CODE
    
    assert_equal ["99"], out
  end
  
  def test_allocate_bytes
    out = rp <<-CODE
    ba = ByteArray.new(16)
    p(ba.fields)
    CODE
    
    assert_equal ["4"], out
  end
  
  def test_create_block
    out = rp <<-CODE
    def blah
      yield
    end
    
    blah { puts "works" }
    CODE
    
    assert_equal ["works"], out
  end
  
  def test_block_given
    out = rp <<-CODE
    def blah
      block_given?
    end
    
    out = blah() { true }
    p out
    out = blah()
    p out
    CODE
    
    assert_equal ["true", "false"], out
  end
  
  def test_block_call
    # test_block_given tests that block_call works.
  end
  
  def test_io_write
    out = rp <<-CODE
    STDOUT.write "hello evan\\n"
    CODE
    
    assert_equal ["hello evan"], out
  end
  
  def test_io_read
    code = <<-CODE
    puts STDIN.read(5)
    CODE
    
    say = "hello"
    out = run_code(code, 1, say)
    assert_equal say, out.strip
  end
  
  def test_create_pipe
    out = rp <<-CODE
    r, w = IO.pipe
    w.puts "test_create_pipe\\n"
    puts r.read(16)
    CODE
    
    assert_equal ["test_create_pipe"], out
  end
  
  def test_io_open
    File.open("code-cache/tmp_io_open", "w") do |fd|
      fd << "test 1234\n"
    end
    
    out = rp <<-CODE
    fd = File.new("code-cache/tmp_io_open","r")
    puts fd.read(9)
    fd.close
    CODE
    
    assert_equal ["test 1234"], out
  end
  
  def test_io_close
    File.open("code-cache/tmp_io_open", "w") do |fd|
      fd << "test 1234\n"
    end
    
    out = rp <<-CODE
    fd = File.new("code-cache/tmp_io_open","r")
    p fd.closed?
    fd.close
    p fd.closed?
    begin
      fd.close
      puts "worked"
    rescue Object => e
      p e.class
    end
    CODE
    
    assert_equal ["false", "true", "IOError"], out
  end
  
  def test_gettimeofday
    i = Time.now.to_i
    out = rp <<-CODE
    t = Time.now
    p(t.to_i > 1000000)
    CODE
    assert_equal ["true"], out
  end
  
  def test_strftime
    t = Time.now
    out = rp <<-CODE
    t = Time.now
    puts t
    CODE
    assert_equal t.to_s, out.first.to_s
  end
  
  def test_fixnum_to_s
    i = 54352344
    out = rp <<-CODE
    puts #{i}.to_s(18)
    CODE
    
    assert_equal i.to_s(18), out.first
  end
  
  def test_logical_class
    out = rp <<-CODE
    p 10.class
    p :blah.class
    p [].class
    CODE
    
    assert_equal ["Fixnum", "Symbol", "Array"], out
  end
  
  def test_object_id
    out = rp <<-CODE
    p 10.object_id
    p :blah.object_id
    p [].object_id
    CODE
    
    out.map { |i| i.to_i }.each do |e|
      assert e > 0
    end
  end
  
  def test_splat
    out = rp <<-CODE
    def do_splat(*args)
      args
    end
    
    p do_splat(992, :blah, 77)
    CODE
    
    assert_equal "[992, :blah, 77]", out.first
    
  end
  
  def test_sleep
    t = Time.now
    out = rp <<-CODE
    Process.sleep(5)
    CODE
    
    t2 = Time.now
    assert(t2 - t >= 5)
  end
end
