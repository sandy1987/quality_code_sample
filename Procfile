web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
resque: env TERM_CHILD=1 COUNT=1 QUEUES=* bundle exec rake resque:workers