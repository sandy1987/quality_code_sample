require 'resque/tasks'

task "resque:setup" => :environment

# # Run following command to start worker to work on ANY queue
# don't use this old style -> QUEUE=* rake environment resque:work
# Use this -> TERM_CHILD=1 QUEUES=* rake resque:work