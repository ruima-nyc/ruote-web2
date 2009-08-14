require File.dirname(__FILE__) + '/../config/environment_ruote'
require 'drb/drb'

#require File.dirname(__FILE__) + '/../config/boot'
$: << "#{RAILS_ROOT}/vendor/plugins/ruote_plugin/lib_ruote"

require 'openwfe/engine/engine'
require 'openwfe/engine/fs_engine'
require 'openwfe/extras/expool/db_errorjournal'
require 'openwfe/extras/expool/db_history'
require 'logger'
require 'fileutils'


begin
  require "#{RAILS_ROOT}/lib/ruote.rb"
  puts ".. found #{RAILS_ROOT}/lib/ruote.rb"
rescue LoadError => le
  puts ".. couldn't load #{RAILS_ROOT}/lib/ruote.rb :\n#{le}"
end

#require 'openwfe/participants/participants'


INDEX_URI="druby://localhost:8888"

class OpenWFE::FsPersistedEngine
  include DRb::DRbUndumped
end

module  OpenWFE::Logging
   def linfo (message=nil, &block)
	if block
          puts "#{log_prepare(message)} - #{block.call}"
        else
          puts "#{log_prepare(message)}"
        end
        do_log(:info, message, &block)
    end
end

class RuoteFactory

  def initialize()
    @engine = nil
  end

  def get_engine()
    if @engine.nil?
      # make the filename safe, then declare it to be so

      h = defined?(RUOTE_ENV) ? RUOTE_ENV : {}

      h[:engine_class] ||= OpenWFE::FsPersistedEngine
      #h[:engine_class] = OpenWFE::Extras::DbPersistedEngine
      # the type of engine to use

      unless h[:logger]
        h[:logger] = Logger.new("log/ruote_#{RAILS_ENV}.log", 10, 1024000)
        #h[:logger].level = (RAILS_ENV == 'production') ? Logger::INFO : Logger::DEBUG
        h[:logger].level = Logger::INFO
      end

      h[:work_directory] ||= "work_#{RAILS_ENV}"

      h[:ruby_eval_allowed] ||= true
      # the 'reval' expression and the ${r:some_ruby_code} notation are allowed

      h[:dynamic_eval_allowed] ||= true
      # the 'eval' expression is allowed

      h[:definition_in_launchitem_allowed] ||= true
      # launchitems (process_items) may contain process definitions

      engine_klass = h.delete(:engine_class)
      @engine = engine_klass.new(h)

      @engine.init_service(:s_history, OpenWFE::Extras::QueuedDbHistory)

      @engine.init_service(:s_error_journal, OpenWFE::Extras::DbErrorJournal)

      @engine.reload
      
      puts ".. Ruote workflow/BPM engine started (DRb Server Mode)"
      @engine
    end
    return @engine
  end

end

FRONT_OBJECT=RuoteFactory.new()


$SAFE = 0   # disable eval() and friends

DRb.start_service(INDEX_URI, FRONT_OBJECT)
puts ".. Ruote DRb server is listening... "
DRb.thread.join
