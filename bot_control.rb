require 'daemons'

Daemons.run('bot.rb', log_output: true, monitor: true, backtrace: true)