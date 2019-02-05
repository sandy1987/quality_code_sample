require 'rest-client'
require 'base64'
require 'net/http'
require 'json'

class RunResqueJob
  @queue = :aqueue
  def self.perform args, extrenal = false
    args = args.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    target = extrenal ? args[:target] : ( File.join "#{APP_CONFIG[:https_eanbled] ? 'https://' : 'http://' }", APP_CONFIG[:app_url], args[:target] )
    auth = 'Basic ' + Base64.encode64( "#{args[:background_user] || Rails.application.secrets.background_user}:#{args[:background_password] || Rails.application.secrets.background_password}" ).chomp
    response = RestClient::Request.execute(
      method: args[:http_method] || :get,
      url: target,
      payload: args,
      timeout: args[:http_timeout] || 60,
      open_timeout: args[:http_open_timeout] || 10,
      headers: { 'Authorization' => auth, 'Content-Type' => 'application/json' }
    )
  end
end

# This one is used for executing by worker locally
class RunTrackingResqueJob
  @queue = :atracking
  def self.perform args
    TrackingManager.manage args
  end
end

# This one is used for executing by worker locally
class RunSentimentResqueJob
  @queue = :sentiment
  def self.perform args
    begin
      text =   args['text']
      secret = Rails.application.secrets.algorithmia_key
      r = `curl -X POST -d '"#{text}"' -H 'Content-Type: application/json' -H 'Authorization: Simple #{secret}' https://api.algorithmia.com/v1/algo/nlp/SentimentAnalysis/0.1.2`
      r = JSON.parse r
      if args['type'] == 'question'
        Question.find(args['qid'].to_s).update(sentiment: r['result'].to_i)
      elsif args['type'] == 'comment'
        Question.find(args['qid']).answers.find(args['aid']).comments.find(args['cid']).update(sentiment: r['result'].to_i)
      end
    rescue => e
      Rails.logger.error "Unable to retrieve sentiment. Args is #{args} . Error is #{e.message} "
    end
  end
end



