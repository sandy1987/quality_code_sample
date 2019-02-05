class QuestionSerializer < ActiveModel::Serializer
  attributes :qid, :text, :asked_by_user, :is_answerer, :is_asker, :requested_answer, :requestor_count, :asked_to, :answer_count, :popularity_point, :video_alert_type, :asked_to_ids

  def qid
    object._id.to_s
  end

  def answer_count
    # if a video is uploaded for thsi question, but transcoding is not finished then it should not be counted towards an answer yet
    (object.answers.select { |e| 
      e.status == 'active' && (  e.transcoding_video_status.present? ? (e.transcoding_video_status == 'finished') : true   ) 
    }.length) rescue 0
  end

  def asked_by_user
    user = serialization_options[:users].select{ |v| v._id.to_s == object.asked_by_user.to_s }.first
    UserSimpleSerializer.new(user).attributes if user
  end

  def requestor_count
    object.requestor_count || 0
  end

  def is_answerer
    (object.asked_to || []).include?(serialization_options[:loggedin_user_id])
  end

  def is_asker
    object.asked_by_user.to_s == serialization_options[:loggedin_user_id]
  end

  def requested_answer
    (object.requestors || []).include?(serialization_options[:loggedin_user_id])
  end

  def asked_to
    ra = serialization_options[:users].select{ |v| (object.asked_to || []).include?(v._id.to_s) }.map do |user|
      user_serializer = UserSerializer.new(user)
      user_serializer.serialization_options = serialization_options
      user_serializer.serialization_options[:question] = object
      user_serializer.attributes
    end
    # ra.sort_by { |h| h[:answer] ? 0 : 1 } # sort to keep all un-answered celebrity ALWAYS at the bottom
    ra.sort_by { |h| h[:answer] ? (h[:answer][:updated_at]) : Time.now } # sort to keep all un-answered celebrity ALWAYS at the bottom and most recent at top
  end

  def asked_to_ids
    asked_to.map {|e| e[:uid]}
  end

  def video_alert_type
    return "none" if !serialization_options[:loggedin_user_id].present? || !is_answerer
    begin 
      asked_to.each { |e| 
        if e[:uid] == serialization_options[:loggedin_user_id] && e[:answer].present? && e[:answer][:transcoding_video_status].present? 
          return "failed" if %w(failed failed_locally).include?(e[:answer][:transcoding_video_status])
          return "processing" unless e[:answer][:transcoding_video_status] == "finished"
        end
      }
    rescue
    end
    "none"
  end
end
