#!/usr/bin/env ruby

require 'optparse'
require './lib/cquery.rb'

options =
{
  :source => "",
  :output => "",
  :type   => "",
  :css    => ""
}

opts = OptionParser.new do |opts|
  opts.banner = "Simple css selectors report."

  opts.on("-s", "--source SOURCE", "Source dir for html files") do |source|
    options[:source] = source
  end

  opts.on("-c", "--css CSS", "css file to extract selectors") do |css|
    options[:css] = css
  end

  opts.on("-o", "--output OUTPUT", "Output report file") do |output|
    options[:output] = output
  end

  opts.on("-t", "--type TYPE", "Type, css or html. html is faster") do |type|
    options[:type] = type.to_sym
  end

  opts.on_tail("-h", "--help", "Show this message.") do
    puts opts
    exit
  end
end

opts.parse!

raise ParseError, "source is empty" if options[:source].empty?
raise ParseError, "type is empty" if options[:type].empty?
raise ParseError, "css is empty" if options[:css].empty?

Cquery::Selector.new :type => options[:type],
  :basedir => options[:source],
  :css     => options[:css]
