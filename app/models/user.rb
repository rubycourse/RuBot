class User < ActiveRecord::Base
  require 'pp'
  validates :slack_id, uniqueness: true

  # def self.user_age
  #   puts "Running User.user_age."
  #   @users = User.all
  #   @users.each do |user|
  #     #user age is in days (86400 seconds).
  #     user.age = (Time.now - user.created_at) / 86400
  #     user.save
  #   end
  # end

  def get_student_data(user)
    puts user
    key = HTTParty.post(
      "https://registrar-window-api.udacity.com/authenticate", 
      :body => 
        {:email =>"steven.worley@udacity.com", 
        :password => ENV['REGISTRAR_PW']}.to_json, 
        :headers => {'content-type' => 'application/json'}
    )
    data = HTTParty.get(
      "https://registrar-window-api.udacity.com/api/v1/accounts/#{user.email}?projection=full", 
      :headers => {'Authorization' => 'JWT ' + key}
      )
    return data
  end

  def check_auth(data)
    auth_err = false
    if data.include?("NotAuthorizedError")
      puts "NotAuthorizedError, usually because slack email doesn't match udacity email."
      auth_err = true
      puts 'user.enrolled = email mismatch'
    end
  end

  def memberships_nil?(data)
    if data["memberships"] == nil
      puts "NO MEMBERSHIPS as of: #{Time.now.strftime('%D')}"
      # user.enrolled = "NO MEMBERSHIPS as of: #{Time.now.strftime('%D')}"
      return true
    end
  end

  def set_subscriptions(type, data)
    #Case of user with free and paid?
    data["memberships"][type].each do |object|
      if object["group_key"] == Rails.application.config.ndkey
        puts "#{type}: #{object["group_key"]}"
        # user.enrolled = "#{type} as of: #{Time.now.strftime('%D')}"
        puts "USERSAVE"
        # user.save
      end
    end
  end

  @@membership_types = [
    "ENROLLED_PAID", 
    "ENROLLED_MANUALLY", 
    "ENROLLED_BD", 
    "ENROLLED_FREE", 
    "UNENROLLED"
  ]

  def check_enrollment_status(user)
    data = get_student_data(user)
    auth_err = check_auth(data)
    pp data
    unless auth_err == true
      no_memberships = memberships_nil?(data)
      unless no_memberships == true
        @@membership_types.each do |type|
          if data["memberships"][type]
            set_subscriptions(type, data)
          end
        end
      end
    end
  end

end