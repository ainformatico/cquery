#!/usr/bin/env ruby

# system
require 'pathname'
require 'rubygems'

# gems
require 'nokogiri'
require 'css_parser'
require 'progressbar'

module Cquery
  class Selector
    attr_accessor :objects

    def initialize(options)
      raise ArgmentError unless options.kind_of? Hash
      raise ArgmentError unless options.has_key? :type
      raise ArgmentError unless options.has_key? :basedir
      @files   = []
      @opts    = {}
      @output  = ""
      @regex   = /(^\*(::(.*))?)|(^(body|html)$)|:(hover|before|after|focus)/
      @opts =
      {
        :type    => "css",
        :output  => "output.md",
        :basedir => "",
        :css     => "",
        :format  => :markdown
      }.merge(options)
      basename = Pathname.new(@opts[:basedir])
      @files = Dir[basename.join("*.html")]
      case @opts[:type]
      when :css
        by_css
      when :html
        by_html
      else
        raise TypeError, "bad :type"
      end
      save_report
    end

    def by_css
      css_parser = load_css(@opts[:css])
      css_total = selector_length(css_parser)
      bar = progress_bar(css_total)
      css_parser.each_selector do |selector, declaration, spec|
        unless selector.match(@regex)
          bar.inc
          write_to_file :title => selector
          @files.each do |file|
            items  = html_parser(file).css(selector)
            unless items.empty?
              write_to_file :type => @opts[:type], :item => get_filename(file), :total => items.length
            end
          end
        end
      end
    end

    def by_html
      css_parser = load_css(@opts[:css])
      bar = progress_bar(@files.length)
      @files.each do |file|
        bar.inc
        parser = html_parser(file)
        write_to_file :title => get_filename(file)
        css_parser.each_selector do |selector, declaration, spec|
          unless selector.match(@regex)
            items = parser.css(selector)
            unless items.empty?
              write_to_file :type => @opts[:type], :item => selector, :total => items.length
            end
          end
        end
      end
    end

  private
    def progress_bar(lenght)
      ProgressBar.new("matching", lenght)
    end

    def load_css(url)
      css_file    = url
      css_parser  = CssParser::Parser.new
      css_parser.load_file!(css_file)
      return css_parser
    end

    def html_parser(file)
      Nokogiri::HTML(File.read(file))
    end

    def selector_length(css_parser)
      css_total = 0
      css_parser.each_selector {css_total += 1}
      return css_total
    end

    def save_report
      @report = File.open(@opts[:output], "w")
      case @opts[:format]
      when :markdown
        @report.puts @output
      end
      @report.close
    end

    def write_to_file(opts)
      case @opts[:format]
      when :markdown
        if opts.has_key? :title
          @output.concat "#{opts[:title]}\n#{"-" * 60}\n"
        else
          @output.concat "* #{opts[:item]} => #{opts[:total]}\n"
        end
      end
    end

    def get_filename(path)
      Pathname.new(path).basename.to_s
    end

  end
end
