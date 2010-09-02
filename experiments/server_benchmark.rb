#!/usr/bin/env ruby

require "rubygems"
require "active_support"

require "client"

class Benchmkarker

  def benchmark_snappiness
    sc = Client.new 33.324, 22.112, 100
    rc = Client.new 33.321, 22.115, 100

    in_time = 0
    out_time = 0
    data = "{...}"
    st = Thread.new{out_time = Time.now; sc.share :pass, data}
    rt = Thread.new{rc.receive :pass; in_time = Time.now}
    st.join; rt.join

    puts "instant share/receive took #{(in_time - out_time)/1000} ms"
  end

  def benchmark_capacity
    hoc_count = 1000
    data = "{...}"

    threads = []
    flooding_started = Time.now
    for i in 1..hoc_count
      threads << Thread.new{ (Client.new 33.324, 22.112, 100).share :pass, data }
      threads << Thread.new{ (Client.new 33.321, 22.115, 100).receive :pass }
    end

    threads.each{|t| t.join}

    puts "#{hoc_count} hocs took #{(Time.now - flooding_started)} s"
  end
  
end

benchmarker = Benchmkarker.new
methods = benchmarker.public_methods.select{|m| m.starts_with? "benchmark"}
methods.each {|b| benchmarker.share b.to_sym}
