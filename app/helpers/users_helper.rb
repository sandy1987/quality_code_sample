module UsersHelper

  def celebrity_checked? resource
    params[:user].present? ? ( params[:celebrity] ? true : false ) : User.is_celebrity?(resource)
  end

  def celebrity_user_list limit
    list_based_on_search_type
    case limit
    when "all"
      @celebrity_users = @celeb_list.all.uniq
    when "auto_suggest"
      @celebrity_users = @celeb_list.map(&:name)
    when "paginate"
      @celebrity_users = @celeb_list.uniq.paginate( page: params[:page_number], per_page: APP_CONFIG[:items_per_page] )
    end
  end

  def create_celebrities data
    user = User.where(email: "#{username(data)}@mailinator.com").first_or_initialize
    user.name           = "#{data[0]} #{data[1]}"
    user.categories     = [data[2]]
    user.username       = @username
    user.url[:facebook] = data[3].present? ? update_url(data[3]) : 'https://www.facebook.com'
    user.url[:twitter]  = data[4].present? ? update_url(data[4]) : 'https://www.twitter.com'
    user.url[:website]  = update_url(data[5])
    user.save(validate: false) 
    user.update(confirmed_at: DateTime.now)
    user.add_role :celebrity
  end

  def error_field? resource, field
    t(:error_field) if ( resource.errors[:url].any? && resource.errors[:url].keys.include?(field.to_sym) )
  end

  def field_value field, f
    params[:user][field] rescue nil || f.object[field]
  end

  def import file
    spreadsheet = open_spreadsheet(file)
    unless flash[:error]
      (2..spreadsheet.last_row).each do |i|
        create_celebrities spreadsheet.row(i).map{|d| d.try(:strip)} rescue false
      end
      flash[:notice] = t(:uploading_done)
    end
  end

  def list_based_on_search_type
    @search = params[:search_by]
    @celeb_list = users.celebrities.where( name: Regexp.new( Regexp.escape(@search), "i" ), status: 'active')
  end

  def url_field_value field
    params[:user][:url][field] rescue nil || current_user.url[field]
  end

  def user_profile_link user, provider
    user.url[ provider ] 
  end

  def user_remembered
    if params[:user].present?
      params[:user][:remember_me] == "1" ? true : false
    else
      cookies.permanent[:remember_detail] ? true : false 
    end
  end

  def users
    params[:asked_to].present? ? User.not_in( _id: params[:asked_to] ) : User
  end

  def username data
    fname = data[0].downcase.gsub(' ','') rescue nil
    lname = data[1].downcase.gsub(' ','') rescue nil
    @username = if lname.present?
        "#{fname.first}#{lname}"
      elsif fname.length >= 4
        fname
      else
        "#{fname}1234"
      end
  end

end
