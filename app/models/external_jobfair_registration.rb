class ExternalJobfairRegistration
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # include Validatable

#  validates_presence_of :company_name, :street_address, :city, :state, :zip
#  validates_presence_of :contact_name, :phone, :fax, :email
#  validates_presence_of :website, :description

  validates :company_name, :presence => true
  validates :street_address, :presence => true
  validates :city, :presence => true
  validates :state, :presence => true
  validates :zip, :presence => true
  validates :contact_name,  :presence => true
  validates :phone,  :presence => true
  validates :fax,  :presence => true
  validates :email, :presence => true
  validates :website, :presence => true
  validates :description, :presence => true
  
  attr_accessor :company_name, :street_address, :city, :state, :zip
  attr_accessor :contact_name, :phone, :fax, :email
  attr_accessor :website, :description
  attr_accessor :electrical, :lunches, :directory_ad, :security_clearance

  def initialize(values={})

    @company_name = values[:company_name]
    @street_address = values[:street_address]
    @city = values[:city]
    @state = values[:state]
    @zip = values[:zip]

    @contact_name = values[:contact_name]
    @phone = values[:phone]
    @fax = values[:fax]
    @email = values[:email]

    @website = values[:website]
    @description = values[:description]

    @electrical = values[:electrical]
    @lunches = values[:lunches]
    @directory_ad = values[:directory_ad]
    @security_clearance = values[:security_clearance]

  end


  def persisted?
    false
  end

end

