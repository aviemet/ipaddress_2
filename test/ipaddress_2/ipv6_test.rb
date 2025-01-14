require 'test_helper'

class IPv6Test < Minitest::Test

  def setup
    @klass = IPAddress::IPv6

    @compress_addr = {
      "2001:db8:0000:0000:0008:0800:200c:417a" => "2001:db8::8:800:200c:417a",
      "2001:db8:0:0:8:800:200c:417a" => "2001:db8::8:800:200c:417a",
      "ff01:0:0:0:0:0:0:101" => "ff01::101",
      "0:0:0:0:0:0:0:1" => "::1",
      "0:0:0:0:0:0:0:0" => "::"}

    @valid_ipv6 = { # Kindly taken from the python IPy library
      "FEDC:BA98:7654:3210:FEDC:BA98:7654:3210" => 338770000845734292534325025077361652240,
      "1080:0000:0000:0000:0008:0800:200C:417A" => 21932261930451111902915077091070067066,
      "1080:0:0:0:8:800:200C:417A" => 21932261930451111902915077091070067066,
      "1080:0::8:800:200C:417A" => 21932261930451111902915077091070067066,
      "1080::8:800:200C:417A" => 21932261930451111902915077091070067066,
      "FF01:0:0:0:0:0:0:43" => 338958331222012082418099330867817087043,
      "FF01:0:0::0:0:43" => 338958331222012082418099330867817087043,
      "FF01::43" => 338958331222012082418099330867817087043,
      "0:0:0:0:0:0:0:1" => 1,
      "0:0:0::0:0:1" => 1,
      "::1" => 1,
      "0:0:0:0:0:0:0:0" => 0,
      "0:0:0::0:0:0" => 0,
      "::" => 0}

    @invalid_ipv6 = [":1:2:3:4:5:6:7",
                     ":1:2:3:4:5:6:7",
                     "2002:516:2:200",
                     "dd"]

    @networks = {
      "2001:db8:1:1:1:1:1:1/32" => "2001:db8::/32",
      "2001:db8:1:1:1:1:1::/32" => "2001:db8::/32",
      "2001:db8::1/64" => "2001:db8::/64"}

    @ip = @klass.new "2001:db8::8:800:200c:417a/64"
    @network = @klass.new "2001:db8:8:800::/64"
    @network2 = @klass.new "2001:db8:8::/48"
    @arr = [8193,3512,0,0,8,2048,8204,16762]
    @hex = "20010db80000000000080800200c417a"

    @link_local = [
      "fe80::",
      "fe80::1",
      "fe80::208:74ff:feda:625c",
      "fe80:0000:0000:0000:0000:0000:0000:0000",
      "febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
      "fe80::/10",
      "fe80::/11",
      "fe80::/20",
      "fe80::/30",
      "fe80::/30",
      "fe80::/63",
      "fe80::/64",
      "fe80::/65"]

    @not_link_local = [
      "::",
      "::1",
      "ff80:03:02:01::",
      "2001:db8::8:800:200c:417a"]

    @unique_local = [
      "fc00::/7",
      "fc00::/8",
      "fd00::/8",
      "fd12:3456:789a:1::1",
      "fd12:3456:789a:1::/64",
      "fc00::1"]

    @not_unique_local = [
      "fc00::/6",
      "::",
      "::1",
      "fe80::",
      "fe80::1",
      "fe80::/64"]

  end

  def test_attribute_address
    addr = "2001:0db8:0000:0000:0008:0800:200c:417a"
    assert_equal addr, @ip.address
  end

  def test_initialize
    assert_instance_of @klass, @ip
    @invalid_ipv6.each do |ip|
      assert_raises(ArgumentError) {@klass.new ip}
    end
    assert_equal 64, @ip.prefix

    assert_raises(ArgumentError) {@klass.new nil }
    assert_raises(ArgumentError) {
      @klass.new "::10.1.1.1"
    }
  end

  def test_attribute_groups
    assert_equal @arr, @ip.groups
  end

  def test_method_as_json
    ip = @klass.new("2001:db8::8:800:200c:417a/64")
    assert_equal "2001:db8::8:800:200c:417a/64", ip.as_json
  end

  def test_method_hexs
    arr = "2001:0db8:0000:0000:0008:0800:200c:417a".split(":")
    assert_equal arr, @ip.hexs
  end

  def test_method_to_i
    @valid_ipv6.each do |ip,num|
      assert_equal num, @klass.new(ip).to_i
    end
  end

  def test_method_bits
    bits = "0010000000000001000011011011100000000000000000000" +
      "000000000000000000000000000100000001000000000000010000" +
      "0000011000100000101111010"
    assert_equal bits, @ip.bits
  end

  def test_method_first
    ip = @klass.new("2001:db8:8:800::/64")
    assert_instance_of @klass, ip.first
    assert_equal "2001:db8:8:800::", ip.first.to_s
    ip = @klass.new("2001:db8:8::/48")
    assert_instance_of @klass, ip.first
    assert_equal "2001:db8:8::", ip.first.to_s
    ip = @klass.new("2001:db8::/32")
    assert_instance_of @klass, ip.first
    assert_equal "2001:db8::", ip.first.to_s
    ip = @klass.new("2001:db8::8:800:200c:417a/64")
    assert_instance_of @klass, ip.first
    assert_equal "2001:db8::", ip.first.to_s
  end

  def test_method_last
    ip = @klass.new("2001:db8:8:800::/64")
    assert_instance_of @klass, ip.last
    assert_equal  "2001:db8:8:800:ffff:ffff:ffff:ffff", ip.last.to_s
    ip = @klass.new("2001:db8:8::/48")
    assert_instance_of @klass, ip.last
    assert_equal "2001:db8:8:ffff:ffff:ffff:ffff:ffff", ip.last.to_s
    ip = @klass.new("2001:db8::/32")
    assert_instance_of @klass, ip.last
    assert_equal "2001:db8:ffff:ffff:ffff:ffff:ffff:ffff", ip.last.to_s
    ip = @klass.new("2001:db8::8:800:200c:417a/64")
    assert_instance_of @klass, ip.last
    assert_equal  "2001:db8::ffff:ffff:ffff:ffff", ip.last.to_s
  end

  def test_method_prefix=()
    ip = @klass.new "2001:db8::8:800:200c:417a"
    assert_equal 128, ip.prefix
    ip.prefix = 64
    assert_equal 64, ip.prefix
    assert_equal "2001:db8::8:800:200c:417a/64", ip.to_string
  end

  def test_method_mapped?
    assert_equal false, @ip.mapped?
    ip6 = @klass.new "::ffff:1234:5678"
    assert_equal true, ip6.mapped?
  end

  def test_classmethod_summarize
    # Should return self if only one network given
    assert_equal [@ip.network], @klass.summarize(@ip)

    # Summarize homogeneous networks
    ip1 = @klass.new("2001:db8:8:800::1/64")
    ip2 = @klass.new("2001:0db8:8:801::2/64")
    assert_equal ["2001:db8:8:800::/63"], @klass.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::1/64")
    ip2 = @klass.new("2001:db8:8:801::1/64")
    ip3 = @klass.new("2001:db8:8:802::1/64")
    ip4 = @klass.new("2001:db8:8:803::1/64")
    assert_equal ["2001:db8:8:800::/62"], @klass.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
    assert_equal ["2001:db8:8:800::/62"], @klass.summarize(ip4,ip3,ip2,ip1).map{|i| i.to_string}

    # Summarize non homogeneous networks
    ip1 = @klass.new("2001:db8:8:800::/63")
    ip2 = @klass.new("2001:db8:9:800::/64")
    assert_equal ["2001:db8:8:800::/63","2001:db8:9:800::/64"], @klass.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8::/32")
    ip2 = @klass.new("2001:db8:8:800::/64")
    assert_equal ["2001:db8::/32"], @klass.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::/63")
    ip2 = @klass.new("2002:db8:8:800::/64")
    assert_equal ["2001:db8:8:800::/63","2002:db8:8:800::/64"], @klass.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::/63")
    ip2 = @klass.new("2001:db8:8:802::/63")
    ip3 = @klass.new("2001:db8:9:800::/64")
    ip4 = @klass.new("2001:db8:6:800::/64")
    assert_equal ["2001:db8:6:800::/64","2001:db8:8:800::/62","2001:db8:9:800::/64"],
              @klass.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:801::1/64")
    ip2 = @klass.new("2001:db8:8:802::1/64")
    ip3 = @klass.new("2001:db8:8:803::1/64")
    ip4 = @klass.new("2001:db8:8:804::1/64")
    result = ["2001:db8:8:801::/64","2001:db8:8:802::/63","2001:db8:8:804::/64"]
    assert_equal result, @klass.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
    assert_equal result, @klass.summarize(ip4,ip3,ip2,ip1).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::1/64")
    ip2 = @klass.new("2002:db8:9:800::1/64")
    ip3 = @klass.new("2004:db8:8:800::1/64")
    ip4 = @klass.new("2004:db8:8:801::2/64")
    result = ["2001:db8:8:800::/64","2002:db8:9:800::/64","2004:db8:8:800::/63"]
    assert_equal result, @klass.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}

    ips = [@klass.new("2001:db8:8:800::1/128"),
           @klass.new("2001:db8:9:800::1/64")]
    result = ["2001:db8:8:800::1/128", "2001:db8:9:800::/64"]
    assert_equal result, @klass.summarize(*ips).map{|i| i.to_string}

    ips = [@klass.new("2091:db8:8:800::1/128"),
           @klass.new("2001:db8:9:900::1/128")]
    result = ["2001:db8:9:900::1/128", "2091:db8:8:800::1/128"]
    assert_equal result, @klass.summarize(*ips).map{|i| i.to_string}

    ips = [@klass.new("2004:db8:8:800::1/128"),
           @klass.new("2001:db8:8:800::1/128")]
    result = ["2001:db8:8:800::1/128", "2004:db8:8:800::1/128"]
    assert_equal result, @klass.summarize(*ips).map{|i| i.to_string}
  end

  def test_method_plus
    ip1 = @klass.new("2001:db8:8:800::1/64")
    ip2 = @klass.new("2001:0db8:8:801::2/64")
    assert_equal ["2001:db8:8:800::/63"], (ip1+ip2).map{|i| i.to_string}

    ip2 = @klass.new("2001:db8:8:802::1/64")
    assert_equal [ip1.network.to_string, ip2.network.to_string],
    (ip1 + ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::/63")
    ip2 = @klass.new("2001:db8:8:900::/64")
    assert_equal ["2001:db8:8:800::/63","2001:db8:8:900::/64"], (ip1+ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::/64")
    ip2 = @klass.new("2001:db8:8:800:c000::/66")
    assert_equal ["2001:db8:8:800::/64"], (ip1+ip2).map{|i| i.to_string}

    ip1 = @klass.new("2001:db8:8:800::/63")
    ip2 = @klass.new("2001:db9:8:800::/64")
    assert_equal ["2001:db8:8:800::/63","2001:db9:8:800::/64"], (ip1+ip2).map{|i| i.to_string}
  end

  def test_method_split
    assert_raises(ArgumentError) {@ip.split(0)}
    # assert_raises(ArgumentError) {@ip.split(257)}
    
    assert_equal @ip.network, @ip.split(1).first
    
    arr =  ["2001:db8:8::/51", "2001:db8:8:2000::/51", "2001:db8:8:4000::/51", 
            "2001:db8:8:6000::/51", "2001:db8:8:8000::/51", "2001:db8:8:a000::/51",
            "2001:db8:8:c000::/51", "2001:db8:8:e000::/51"]
    assert_equal arr, @network2.split(8).map {|s| s.to_string}
    arr = ["2001:db8:8::/51", "2001:db8:8:2000::/51", "2001:db8:8:4000::/51",
           "2001:db8:8:6000::/51", "2001:db8:8:8000::/51", "2001:db8:8:a000::/51",
           "2001:db8:8:c000::/50"]
    assert_equal arr, @network2.split(7).map {|s| s.to_string}
    arr = ["2001:db8:8::/51", "2001:db8:8:2000::/51", "2001:db8:8:4000::/51",
           "2001:db8:8:6000::/51", "2001:db8:8:8000::/50", "2001:db8:8:c000::/50"]
    assert_equal arr, @network2.split(6).map {|s| s.to_string}
    arr = ["2001:db8:8::/51", "2001:db8:8:2000::/51", "2001:db8:8:4000::/51",
           "2001:db8:8:6000::/51", "2001:db8:8:8000::/49"]
    assert_equal arr, @network2.split(5).map {|s| s.to_string}
    arr =  ["2001:db8:8::/50", "2001:db8:8:4000::/50", "2001:db8:8:8000::/50",
            "2001:db8:8:c000::/50"]
    assert_equal arr, @network2.split(4).map {|s| s.to_string}
    arr = ["2001:db8:8::/50", "2001:db8:8:4000::/50", "2001:db8:8:8000::/49"]
    assert_equal arr, @network2.split(3).map {|s| s.to_string}
    arr = ["2001:db8:8::/49", "2001:db8:8:8000::/49"]
    assert_equal arr, @network2.split(2).map {|s| s.to_string}
    arr = ["2001:db8:8::/48"]
    assert_equal arr, @network2.split(1).map {|s| s.to_string}
  end

  def test_method_literal
    str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net"
    assert_equal str, @ip.literal
  end

  def test_method_group
    @arr.each_with_index do |val,index|
      assert_equal val, @ip[index]
    end
  end

  def test_method_ipv4?
    assert_equal false, @ip.ipv4?
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

  def test_method_network?
    assert_equal true, @network.network?
    assert_equal false, @ip.network?
  end

  def test_method_network_u128
    assert_equal 42540766411282592856903984951653826560, @ip.network_u128
  end

  def test_method_broadcast_u128
    assert_equal 42540766411282592875350729025363378175, @ip.broadcast_u128
  end

  def test_method_size
    ip = @klass.new("2001:db8::8:800:200c:417a/64")
    assert_equal 2**64, ip.size
    ip = @klass.new("2001:db8::8:800:200c:417a/32")
    assert_equal 2**96, ip.size
    ip = @klass.new("2001:db8::8:800:200c:417a/120")
    assert_equal 2**8, ip.size
    ip = @klass.new("2001:db8::8:800:200c:417a/124")
    assert_equal 2**4, ip.size
  end

  def test_method_include?
    assert_equal true, @ip.include?(@ip)
    # test prefix on same address
    included = @klass.new "2001:db8::8:800:200c:417a/128"
    not_included = @klass.new "2001:db8::8:800:200c:417a/46"
    assert_equal true, @ip.include?(included)
    assert_equal false, @ip.include?(not_included)
    # test address on same prefix
    included = @klass.new "2001:db8::8:800:200c:0/64"
    not_included = @klass.new "2001:db8:1::8:800:200c:417a/64"
    assert_equal true, @ip.include?(included)
    assert_equal false, @ip.include?(not_included)
    # general test
    included = @klass.new "2001:db8::8:800:200c:1/128"
    not_included = @klass.new "2001:db8:1::8:800:200c:417a/76"
    assert_equal true, @ip.include?(included)
    assert_equal false, @ip.include?(not_included)
    # string test
    assert_equal true, @ip.include?("2001:db8::8:800:200c:2")
    assert_equal false, @ip.include?("2001:db8:1::8:800:200c:417a")
  end

  def test_method_include_all?
    ip = @klass.new("2001:db8:8:800::1/64")
    addr1 = @klass.new("2001:db8:8:800::2/64")
    addr2 = @klass.new("2001:db8:8:800::8/64")
    assert_equal true, ip.include_all?(addr1,addr2)
    assert_equal false, ip.include_all?(addr1, @klass.new("2002:db8:8:800::2/64"))
  end

  def test_method_to_hex
    assert_equal @hex, @ip.to_hex
  end

  def test_method_to_s
    assert_equal "2001:db8::8:800:200c:417a", @ip.to_s
  end

  def test_method_to_string
    assert_equal "2001:db8::8:800:200c:417a/64", @ip.to_string
  end

  def test_method_to_string_uncompressed
    str = "2001:0db8:0000:0000:0008:0800:200c:417a/64"
    assert_equal str, @ip.to_string_uncompressed
  end

  def test_method_data
    if RUBY_VERSION < "2.0"
      str = " \001\r\270\000\000\000\000\000\b\b\000 \fAz"
    else
      str = " \x01\r\xB8\x00\x00\x00\x00\x00\b\b\x00 \fAz".b
    end
    assert_equal str, @ip.data
  end

  def test_method_reverse
    str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa"
    assert_equal str, @klass.new("3ffe:505:2::f").reverse
  end

  def test_method_compressed
    assert_equal "1:1:1::1", @klass.new("1:1:1:0:0:0:0:1").compressed
    assert_equal "1:0:1::1", @klass.new("1:0:1:0:0:0:0:1").compressed
    assert_equal "1:0:0:1::1", @klass.new("1:0:0:1:0:0:0:1").compressed
    assert_equal "1::1:0:0:1", @klass.new("1:0:0:0:1:0:0:1").compressed
    assert_equal "1::1", @klass.new("1:0:0:0:0:0:0:1").compressed
  end

  def test_method_unspecified?
    assert_equal true, @klass.new("::").unspecified?
    assert_equal false, @ip.unspecified?
  end

  def test_method_loopback?
    assert_equal true, @klass.new("::1").loopback?
    assert_equal false, @ip.loopback?
  end

  def test_method_link_local?
    @link_local.each do |addr|
      assert_equal true, @klass.new(addr).link_local?, addr
    end
    @not_link_local.each do |addr|
      assert_equal false, @klass.new(addr).link_local?, addr
    end
  end

  def test_method_unique_local?
    @unique_local.each do |addr|
      assert_equal true, @klass.new(addr).unique_local?
    end
    @not_unique_local.each do |addr|
      assert_equal false, @klass.new(addr).unique_local?
    end
  end

  def test_method_broadcast
    ip = @klass.new("2001:db8:8:800::/64")
    assert_instance_of @klass, ip.broadcast
    assert_equal  "2001:db8:8:800:ffff:ffff:ffff:ffff", ip.broadcast.to_s
    ip = @klass.new("2001:db8:8::/48")
    assert_instance_of @klass, ip.broadcast
    assert_equal "2001:db8:8:ffff:ffff:ffff:ffff:ffff", ip.broadcast.to_s
    ip = @klass.new("2001:db8::/32")
    assert_instance_of @klass, ip.broadcast
    assert_equal "2001:db8:ffff:ffff:ffff:ffff:ffff:ffff", ip.broadcast.to_s
    ip = @klass.new("2001:db8::8:800:200c:417a/64")
    assert_instance_of @klass, ip.broadcast
    assert_equal  "2001:db8::ffff:ffff:ffff:ffff", ip.broadcast.to_s
  end

  def test_method_network
    @networks.each do |addr,net|
      ip = @klass.new addr
      assert_instance_of @klass, ip.network
      assert_equal net, ip.network.to_string
    end
  end

  def test_method_each
    ip = @klass.new("2001:db8::4/125")
    arr = []
    ip.each {|i| arr << i.compressed}
    expected = ["2001:db8::","2001:db8::1","2001:db8::2",
                "2001:db8::3","2001:db8::4","2001:db8::5",
                "2001:db8::6","2001:db8::7"]
    assert_equal expected, arr
  end

  def test_method_succ
    ip = @klass.new("2001:db8:0:cd30::/64")
    assert_instance_of @klass, ip.succ
    assert_equal  "2001:db8:0:cd30::1/64", ip.succ.to_string
    ip = @klass.new("::")
    assert_instance_of @klass, ip.succ
    assert_equal  "::1/128", ip.succ.to_string
    ip = @klass.new("::1")
    assert_instance_of @klass, ip.succ
    assert_equal  "::2/128", ip.succ.to_string
    ip = @klass.new("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/64")
    assert_instance_of @klass, ip.succ
    assert_equal  "::/64", ip.succ.to_string
  end

  def test_method_pred
    ip = @klass.new("2001:db8:0:cd30::/64")
    assert_instance_of @klass, ip.pred
    assert_equal  "2001:db8:0:cd2f:ffff:ffff:ffff:ffff/64", ip.pred.to_string
    ip = @klass.new("::")
    assert_instance_of @klass, ip.pred
    assert_equal  "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128", ip.pred.to_string
    ip = @klass.new("::1")
    assert_instance_of @klass, ip.pred
    assert_equal  "::/128", ip.pred.to_string
    ip = @klass.new("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/64")
    assert_instance_of @klass, ip.pred
    assert_equal  "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe/64", ip.pred.to_string
  end

  def test_allocate_addresses
    ip = @klass.new("2001:db8::4/125")
    ip1 = ip.allocate
    ip2 = ip.allocate
    ip3 = ip.allocate
    assert_equal "2001:db8::1", ip1.compressed
    assert_equal "2001:db8::2", ip2.compressed
    assert_equal "2001:db8::3", ip3.compressed
  end

  def test_allocate_can_skip_addresses
    ip = @klass.new("2001:db8::4/125")
    ip1 = ip.allocate(2)
    assert_equal "2001:db8::3", ip1.compressed
  end

  def test_allocate_will_raise_stopiteration
    ip = @klass.new("2001:db8::4/125")
    ip.allocate(6)
    assert_raises (StopIteration) do
      ip.allocate
    end
  end

  def test_method_compare
    ip1 = @klass.new("2001:db8:1::1/64")
    ip2 = @klass.new("2001:db8:2::1/64")
    ip3 = @klass.new("2001:db8:1::2/64")
    ip4 = @klass.new("2001:db8:1::1/65")

    # ip2 should be greater than ip1
    assert_equal true, ip2 > ip1
    assert_equal false, ip1 > ip2
    assert_equal false, ip2 < ip1
    # ip3 should be less than ip2
    assert_equal true, ip2 > ip3
    assert_equal false, ip2 < ip3
    # ip1 should be less than ip3
    assert_equal true, ip1 < ip3
    assert_equal false, ip1 > ip3
    assert_equal false, ip3 < ip1
    # ip1 should be equal to itself
    assert_equal true, ip1 == ip1
    # ip4 should be greater than ip1
    assert_equal true, ip1 < ip4
    assert_equal false, ip1 > ip4
    # test sorting
    arr = ["2001:db8:1::1/64","2001:db8:1::1/65",
           "2001:db8:1::2/64","2001:db8:2::1/64"]
    assert_equal arr, [ip1,ip2,ip3,ip4].sort.map{|s| s.to_string}
    # compare with alien thing
    ip1 = @klass.new('::1')
    ip2 = IPAddress::IPv4.new('127.0.0.1')
    not_ip = String
    assert_nil ip1 <=> ip2
    assert_nil ip1 <=> not_ip
  end

  def test_method_subnet
    assert_raises(ArgumentError) {@network.subnet(63)}
    assert_raises(ArgumentError) {@network.subnet(33)}
    assert_equal %w(2001:db8:8:800::/66 2001:db8:8:800:4000::/66
      2001:db8:8:800:8000::/66 2001:db8:8:800:c000::/66),
      @network.subnet(66).map {|s| s.to_string}
    assert_equal %w(2001:db8:8:800::/65 2001:db8:8:800:8000::/65),
      @network.subnet(65).map {|s| s.to_string}
    assert_equal ["2001:db8:8:800::/64"], @network.subnet(64).map {|s| s.to_string}
  end

  def test_method_supernet
    assert_raises(ArgumentError) {@ip.supernet(67)}
    assert_equal "::/0", @ip.supernet(0).to_string
    assert_equal "::/0", @ip.supernet(-2).to_string
    assert_equal "2001:db8::/63", @ip.supernet(63).to_string
    assert_equal "2001:db8::/32", @ip.supernet(32).to_string
    assert_equal "2001::/20", @ip.supernet(20).to_string
    assert_equal "2000::/8", @ip.supernet(8).to_string
    assert_equal "2001:db8::/32", @klass.new("2001:db8:8:800::1/64").supernet(32).to_string
    assert_equal "2001:c00::/22", @klass.new("2001:db8:8:800::1/64").supernet(22).to_string
  end

  def test_classmethod_expand
    compressed = "2001:db8:0:cd30::"
    expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
    assert_equal expanded, @klass.expand(compressed)
    refute_equal expanded, @klass.expand("2001:0db8:0::cd3")
    refute_equal expanded, @klass.expand("2001:0db8::cd30")
    refute_equal expanded, @klass.expand("2001:0db8::cd3")
  end

  def test_classmethod_compress
    compressed = "2001:db8:0:cd30::"
    expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
    assert_equal compressed, @klass.compress(expanded)
    refute_equal compressed, @klass.compress("2001:0db8:0::cd3")
    refute_equal compressed, @klass.compress("2001:0db8::cd30")
    refute_equal compressed, @klass.compress("2001:0db8::cd3")
  end

  def test_classmethod_parse_data
    str = " \001\r\270\000\000\000\000\000\b\b\000 \fAz"
    ip = @klass.parse_data str
    assert_instance_of @klass, ip
    assert_equal "2001:0db8:0000:0000:0008:0800:200c:417a", ip.address
    assert_equal "2001:db8::8:800:200c:417a/128", ip.to_string
  end

  def test_classhmethod_parse_u128
    @valid_ipv6.each do |ip,num|
      assert_equal @klass.new(ip).to_s, @klass.parse_u128(num).to_s
    end
  end

  def test_classmethod_parse_hex
    assert_equal @ip.to_s, @klass.parse_hex(@hex,64).to_s
  end

  def test_group_updates
    ip = @klass.new("2001:db8::8:800:200c:417a/64")
    ip[2] = '1234'
    assert_equal "2001:db8:4d2:0:8:800:200c:417a/64", ip.to_string
  end

  def test_finds_adjacent_subnet
    refute @klass.new("::/0").find_adjacent_subnet 

    ip = @klass.new("2001:db8::/32")
    assert_equal "2001:db9::/32", ip.find_adjacent_subnet
    assert_equal 32, ip.prefix

    assert_equal "2001:db9::/32", @klass.new("2001:db8::/32").find_adjacent_subnet 
    assert_equal "2001:db8:0:1::/64", @klass.new("2001:db8::/64").find_adjacent_subnet 
    assert_equal "2001:db8:8:2000::/51", @klass.new("2001:db8:8::/51").find_adjacent_subnet 
  end

  def test_method_add
    ip = IPAddress::IPv6.new("fc42:1337::/64")
    assert_equal ip.add(5), IPAddress::IPv6.new("fc42:1337::5/64")
    assert_equal ip.add(IPAddress::IPv6.new("::5/42")), IPAddress::IPv6.new("fc42:1337::5/64")
    assert_equal ip.add(50), IPAddress::IPv6.new("fc42:1337::32/64")
    ip = IPAddress::IPv6.new("fc42:1337::/120")
    assert_equal ip.add(2), IPAddress::IPv6.new("fc42:1337::2/120")
    assert_raises(RuntimeError) {ip.add(256)}
    assert_equal ip.add(256, false), IPAddress::IPv6.new("fc42:1337::100/120")
  end

  def test_method_subtract
    ip = IPAddress::IPv6.new("fc42:1337::5/64")
    assert_equal ip.subtract(5), IPAddress::IPv6.new("fc42:1337::/64")
    assert_equal ip.subtract(IPAddress::IPv6.new("::5/12")), IPAddress::IPv6.new("fc42:1337::0/64")
    assert_raises(RuntimeError) {ip.subtract(11)}
    assert_raises(RuntimeError) {ip.subtract(IPAddress::IPv6.new("::11/66"))}
  end
  
  def test_method_hostpart
    ip = IPAddress::IPv6.new("fc42:1337:0:5::7/64")
    assert_equal ip.hostpart.to_s, "::7"
  end

  def test_method_advance_network
    ip = IPAddress::IPv6.new("fc42:1337:0:0::/64")
    assert_equal ip.advance_network(5), IPAddress::IPv6.new("fc42:1337:0:5::/64")
  end

  def test_method_next_network
    ip = IPAddress::IPv6.new("fc42:1337:0:0::/64")
    assert_equal ip.next_network, IPAddress::IPv6.new("fc42:1337:0:1::/64")
  end
  
  def test_method_regress_network
    ip = IPAddress::IPv6.new("fc42:1337:0:5::/64")
    assert_equal ip.regress_network(4), IPAddress::IPv6.new("fc42:1337:0:1::/64")
  end
  
  def test_method_previous_network
    ip = IPAddress::IPv6.new("fc42:1337:0:5::/64")
    assert_equal ip.previous_network, IPAddress::IPv6.new("fc42:1337:0:4::/64")
  end  


end # class IPv6Test

class IPv6UnspecifiedTest < Minitest::Test

  def setup
    @klass = IPAddress::IPv6::Unspecified
    @ip = @klass.new
    @s = "::"
    @str = "::/128"
    @string = "0000:0000:0000:0000:0000:0000:0000:0000/128"
    @u128 = 0
    @address = "::"
  end

  def test_initialize
    assert_instance_of @klass, @ip
  end

  def test_attributes
    assert_equal @address, @ip.compressed
    assert_equal 128, @ip.prefix
    assert_equal true, @ip.unspecified?
    assert_equal @s, @ip.to_s
    assert_equal @str, @ip.to_string
    assert_equal @string, @ip.to_string_uncompressed
    assert_equal @u128, @ip.to_u128
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

end # class IPv6UnspecifiedTest


class IPv6LoopbackTest < Minitest::Test

  def setup
    @klass = IPAddress::IPv6::Loopback
    @ip = @klass.new
    @s = "::1"
    @str = "::1/128"
    @string = "0000:0000:0000:0000:0000:0000:0000:0001/128"
    @u128 = 1
    @address = "::1"
  end

  def test_initialize
    assert_instance_of @klass, @ip
  end

  def test_attributes
    assert_equal @address, @ip.compressed
    assert_equal 128, @ip.prefix
    assert_equal true, @ip.loopback?
    assert_equal @s, @ip.to_s
    assert_equal @str, @ip.to_string
    assert_equal @string, @ip.to_string_uncompressed
    assert_equal @u128, @ip.to_u128
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

end # class IPv6LoopbackTest

class IPv6MappedTest < Minitest::Test

  def setup
    @klass = IPAddress::IPv6::Mapped
    @ip = @klass.new("::172.16.10.1")
    @s = "::ffff:172.16.10.1"
    @str = "::ffff:172.16.10.1/128"
    @string = "0000:0000:0000:0000:0000:ffff:ac10:0a01/128"
    @u128 = 281473568475649
    @address = "::ffff:ac10:a01"

    @valid_mapped = {'::13.1.68.3' => 281470899930115,
      '0:0:0:0:0:ffff:129.144.52.38' => 281472855454758,
      '::ffff:129.144.52.38' => 281472855454758}

    @valid_mapped_ipv6 = {'::0d01:4403' => 281470899930115,
      '0:0:0:0:0:ffff:8190:3426' => 281472855454758,
      '::ffff:8190:3426' => 281472855454758}

    @valid_mapped_ipv6_conversion = {'::0d01:4403' => "13.1.68.3",
      '0:0:0:0:0:ffff:8190:3426' => "129.144.52.38",
      '::ffff:8190:3426' => "129.144.52.38"}

  end

  def test_initialize
    assert_instance_of @klass, @ip
    @valid_mapped.each do |ip, u128|
      assert_equal u128, @klass.new(ip).to_u128
    end
    @valid_mapped_ipv6.each do |ip, u128|
      assert_equal u128, @klass.new(ip).to_u128
    end
  end

  def test_mapped_from_ipv6_conversion
    @valid_mapped_ipv6_conversion.each do |ip6,ip4|
      assert_equal ip4, @klass.new(ip6).ipv4.to_s
    end
  end

  def test_attributes
    assert_equal @address, @ip.compressed
    assert_equal 128, @ip.prefix
    assert_equal @s, @ip.to_s
    assert_equal @str, @ip.to_string
    assert_equal @string, @ip.to_string_uncompressed
    assert_equal @u128, @ip.to_u128
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

  def test_mapped?
    assert_equal true, @ip.mapped?
  end

end # class IPv6MappedTest
