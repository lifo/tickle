module Tickle
  extend self

  def load_environment
    return if @loaded
    puts "Loading Rails.."
    ENV["RAILS_ENV"] = "test"
    Object.const_set :RAILS_ENV, "test"

    require(File.join(RAILS_ROOT, 'config', 'environment'))
    $: << "#{Rails.root}/test"
    require "#{Rails.root}/test/test_helper"

    @loaded = true
  end

  def run_tests(dir, n = 2)
    dir = "#{Rails.root}/test/#{dir}/**/*_test.rb" unless dir.index(Rails.root)
    groups = Dir[dir].sort.in_groups(n, false)

    pids = []
    n.times do |i|
      pids << Process.fork do
        prepare_databse(:"test_#{i+1}")
        groups[i].each {|f| load(f) unless f =~ /^-/  }
      end
    end

    Signal.trap 'SIGINT', lambda { pids.each {|p| Process.kill("KILL", p)}; exit 1 }

    # Wait...
    Process.waitall
  end

  def prepare_databse(db)
    recreate_db(config[db.to_s])

    ActiveRecord::Base.establish_connection(config[db.to_s])
    ActiveRecord::Schema.verbose = false
    file = ENV['SCHEMA'] || "#{RAILS_ROOT}/db/schema.rb"
    load(file)
  end

  def recreate_db(db_config)
    db = db_config["database"]

    if postgres?
      system("dropdb #{db}")
      ActiveRecord::Base.connection.create_database(db)
    else
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Base.connection.recreate_database(db, db_config)
    end
  end

  def postgres?
    defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) && ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  end

  def config
    ActiveRecord::Base.configurations
  end
end