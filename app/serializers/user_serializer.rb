class UserSerializer < UserSimpleSerializer
  attributes :answer #, :answer_video_status

  def answer
    answer_object = serialization_options[:question].answers.where(user_id: object._id).first if serialization_options[:question].is_a?(Question)
    if answer_object.present?
      answer_serializer = AnswerSerializer.new(answer_object)
      answer_serializer.serialization_options = { }
      answer_serializer.serialization_options[:loggedin_user_id] = serialization_options[:loggedin_user_id]
      answer_serializer.attributes
    end

  end

  # def answer_video_status
  #   return 'na'         if !answer || object.id.to_s != serialization_options[:loggedin_user_id]
  #   return 'failed'     if answer[:transcoding_video_status].present? && %w(failed failed_locally).include?(answer[:transcoding_video_status])
  #   return 'processing' if answer[:transcoding_video_status].present? && answer[:transcoding_video_status] != 'finished'
  # end

end
