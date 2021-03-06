#!/usr/bin/env ruby
# encoding: utf-8


require 'rubygems'
gem 'activesupport',  '~> 2.3.8'
gem 'actionpack',     '~> 2.3.8'
gem 'i18n',           '~> 0.3.5'
gem 'haml'
gem 'rb-appscript'
gem 'sinatra'


module TimeTap
  attr_accessor :config
  
  extend self
  
  
  # CONFIGURATION

  # Are we on 1.9?
  # FIXME: this is wrong! :)
  RUBY19 = RUBY_VERSION.to_f >= 1.9
  
  def config= options = {}
    require 'active_support'
    
    # CONFIG
    @config = HashWithIndifferentAccess.new(options)
    @config[:root] = File.expand_path(config[:root])
    @config[:port] = config[:port].to_i
  end
  
  
  def start options = {}
    # REQUIREMENTS
  
    require 'yaml'
    require 'active_support'
    require 'time_tap/project'
    require 'time_tap/editors'
    require 'time_tap/watcher'
    require 'time_tap/server'
    
    
  
    # SIGNAL HANDLING
  
    Signal.trap("INT")  {exit}
    Signal.trap("TERM") {exit}
  
  
    # WEB SERVER
  
    Thread.abort_on_exception = true
  
    @server = Thread.new {
      Signal.trap("INT")  {exit}
      Signal.trap("TERM") {exit}
    
      Server.run! :host => 'localhost', :port => TimeTap.config[:port]
      exit
    }
  
  
    # WATCHER
  
    include Editors
    Watcher.keep_watching(TextMate)
  end
  
  # Add a plist for OSX's launchd and have *TimeTap* launched automatically at login.
  def install!
    load_plist_info!
    ruby        = config[:ruby] || "/usr/bin/ruby"
    include_dir = '-I'+File.expand_path('../../lib', __FILE__)
    launcher    = File.expand_path('../../bin/timetap', __FILE__)

    puts "\nCreating launchd plist in\n  #{plist_path}"

    File.open(plist_path, 'w') do |file|
      file << <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.eliaesocietas.TimeTap</string>

	<key>Program</key>
	<string>#{ruby}</string>

	<key>ProgramArguments</key>
	<array>
		<string>#{ruby}</string>
		<string>#{include_dir}</string>
		<string>#{launcher}</string>
		<string>-f</string>
	</array>

	<key>OnDemand</key>
	<false/>

	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
      PLIST
    end
  end
  
  def reload!
    load_plist_info!
    command = "launchctl unload #{plist_path}; launchctl load #{plist_path}"
    exec command
  end
  
  private
  
    attr_reader :plist_path, :plist_name
    
    def load_plist_info!
      @plist_name ||= "com.eliaesocietas.TimeTap.plist"
      @plist_path ||= File.expand_path("~/Library/LaunchAgents/#{plist_name}")
    end
    
end
