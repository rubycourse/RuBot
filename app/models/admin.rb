class Admin < ActiveRecord::Base
  validates :email,
             presence: true,
             uniqueness: true,
             format: {
                     message: 'domain must be udacity.com or knowlabs.com',
                     with: /\A[\w+-.]+@udacity.com|knowlabs.com\z/i
                     }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:google_oauth2]

         #:registerable removed to disable signup
         #:recoverable removed to disable password recovery

  def self.from_omniauth(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |admin|
        admin.provider = auth.provider
        admin.uid = auth.uid
        admin.email = auth.info.email
        admin.password = Devise.friendly_token[0,20]
      end
  end
end
