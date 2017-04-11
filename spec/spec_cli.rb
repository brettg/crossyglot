require 'fileutils'
require File.expand_path('../spec_helper', __FILE__)

module Crossyglot::SpecCLIHelpers
  def color(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end
  def red(text); color(text, 31); end
  def green(text); color(text, 32); end
  def yellow(text); color(text, 33); end

  def dot(text, color) print color('.', color); end
  def rdot(text); dot(text, 31); end
  def gdot(text); dot(text, 32); end
  def ydot(text); dot(text, 33); end
end

class Crossyglot::SpecRTCLI
  include SpecCLIHelpers

  def initialize(matcher, skips = [])
    @matcher = matcher
    @skips = skips

    @args = ARGV.dup
    @counts = Hash.new(0)
    @fails = []

    validate!
    parse_flags

    run
    results
  end

  def dot(text, color)
    if @roundtrip_verbose
      puts color(text, color)
    else
      print color('.', color)
    end
  end

  def validate!
    if @args.size < 1
      puts 'Puzzle file(s) required!'
      puts "Usage: #{File.basename($0)} (-v) (-mdfind) (-save) </path/to/puzfile>..."
      puts 'Options:'
      puts '  -v           verbose mode'
      puts "  -mdfind      use mdfind on OS X to find .#{@matcher.file_ext} files"
      puts '  -save-failed save failures to spec/tmp'
      puts 'exiting...'
      exit
    end
  end

  def parse_flags
    @roundtrip_verbose = !!@args.delete('-v')
    @save_fails = 'true'  if @args.delete('-save-fails')

    if @args.delete('-mdfind')
      if RUBY_PLATFORM[/darwin/i]
        @args += `mdfind 'kMDItemFSName = "*.#{@matcher.file_ext}"'`.split("\n").compact
        # Assume they've been copied by this script
        @args.reject! do |f|
          File.identical?(f, TestfileHelper.tmp_output_path(f))
        end
      else
        $stderr.puts red('mdfind only available on OS X')
      end
    end
  end

  def run
    @args.each do |f|
      if File.exists?(f)
        if @skips.include?(f)
          ydot("Skipping known invalid: #{f}")
        else
          if File.size(f) > 0
            matcher = @matcher.new
            begin
              if matcher.matches?(f)
                gdot("Success: #{f}")
                @counts[:success] += 1
              else
                rdot("Fail: #{f}")
                @fails << [f, matcher.failure_message]
              end
            rescue StandardError => e
              rdot("Fail: #{f}")
              @fails << [f, ([e.message] + e.backtrace.map { |l| "\t" + l }).join("\n")]
            end
          else
            ydot("Skipping empty file: #{f}")
            @counts[:skipped] += 1
          end
        end
      else
        $stderr.puts red("File does not exist! Skipping: #{f}")
        @counts[:skipped] += 1
      end
    end
  end


  def save_fail(f)
    FileUtils.cp(f, TestfileHelper.tmp_output_path(f))
  rescue ArgumentError
  end


  def results
    puts  unless @roundtrip_verbose

    unless @fails.empty?
      puts
      puts red('FAILS')
      puts red('#####')
      @fails.each do |f, message|
        puts
        puts red(f)
        puts red(message)
        puts
        save_fail(f)  if @save_fails
      end
    end

    puts green("Success #{@counts[:success]}") + ' | ' + red("Fail #{@fails.size}") + ' | ' +
         yellow("Skipped: #{@counts[:skipped]}")
  end
end
