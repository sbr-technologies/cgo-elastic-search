require "nokogiri"

class Job < ActiveRecord::Base

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :recruiter

  has_many :addresses, :as => :addressable, :dependent => :destroy do
    def [](label)
      find(:first, :conditions => ['label = ?', label.to_s.downcase])
    rescue
      nil
    end
  end

  has_many  :job_applications, :dependent => :destroy, :order => "created_at DESC"

  has_many :inbox_entries, :as => :resource, :dependent => :destroy

  validates_presence_of :code, :title, :description, :education_level


  mapping do
    indexes :id, type: 'integer'
    indexes :code
    indexes :status
    indexes :input_method

    indexes :company_name
    indexes :title
    indexes :body

    indexes :state

    indexes :education_level
    indexes :security_clearance
    indexes :experience_required
    indexes :payrate

    indexes :travel_requirements
    indexes :relocation_cost_paid

    indexes :updated_at, type: 'date'
    indexes :created_at, type: 'date'
    indexes :expires_at, type: 'date'

    indexes :recruiter_id, type: 'integer'
  end


  def as_indexed_json(options={})

    {
      id: id,
      code: code,
      status: status,
      input_method: input_method,

      company_name: company_name,
      title: title,
      body: body,

      education_level: education_level,
      security_clearance: security_clearance,
      experience_required: experience_required,
      payrate: payrate,

      state: state,

      recruiter_id: recruiter_id,

      travel_requirements: travel_requirements,
      relocation_cost_paid: relocation_cost_paid,

      expires_at: expires_at,
      created_at: created_at,
      updated_at: updated_at
    }
  end


  def self.search(query, options={})

      @search_definition = {
        query: {},
        filter: {},
        sort: {created_at: 'desc'}
      }

      __set_filters = lambda do |key, f|
        @search_definition[:filter][:and] ||= []
        @search_definition[:filter][:and] |= [f]
      end

      f = { :term => { 'status' => 'active' }}
      __set_filters.(:status, f)

      f = { range: {
            expires_at:{
              gte: Date.today.iso8601
            }
          }
      }
      #f = { :range => { :expires_at => { :gte => Date.today.iso8601 }}}
      __set_filters.(:expires_at, f)

      logger.debug("State: " + options[:state].to_s)

      unless options[:state].blank?
        logger.debug("Options State No blank")

        if options[:state].kind_of?(Array)
          states = options[:state].collect {|state| state.downcase}
        else
          states = [options[:state].downcase]
        end

        logger.debug("Adding State Filter")
        f = { :term => { 'state' =>states}}
        __set_filters.(:state, f)
      end

      unless options[:employer_name].blank?
        recruiters = Employer.where("name like '%#{employer_name}%'").collect { |e| e.recruiters.collect {|r| r.id} }.flatten
        f = { :term => { 'recruiter_id' => recruiters }}
        __set_filters.(:recruiter_id, f)
      end

      unless query.blank?

        @search_definition[:query] = {
          multi_match: {
            query: query,
            fields: ['title', 'body'],
            operator: 'or'
          }
        }

      else
        @search_definition[:query] = { match_all: {} }
      end

      search_dsl = {query: {
          filtered: {
            query: @search_definition[:query],
            filter: @search_definition[:filter]
          }
        }
      }

      logger.info(search_dsl.inspect)

      __elasticsearch__.search(search_dsl) #@search_definition)

  end


  def active?
    status == "active"
  end

  def expired?
    Time.now.at_beginning_of_day > expires_at.at_beginning_of_day
  end

  def employer
    recruiter.employer rescue nil
  end

  # This is masking the DB's field 'company_name'
  # DISABLED by Fede Jan 10, 2008 to display
  # the real employer for jobs loaded by job wrappers (i.e. JobCentral)
  #
  #def company_name
  #  recruiter.employer.name
  #end

  def location
    # If "addresses" was eager loaded; then search for the "location" address. Otherwise
    # do a scoped find.
    if addresses.length > 0
      addresses.select {|a| a.label == "location"}[0]
    else
      addresses[:location]
    end
  end

  def location=(location)
    location.label = "location"
    addresses << location
  end

  def state
    addresses[:location].state.strip rescue "0"
  end

  # Extract text from HTML fragment.
  def body
    doc = Nokogiri.parse("<html><body>#{description}</body></html>")
    return doc.text
  end

  def posted_months_ago

    tstamp = (updated_at || created_at).to_date

    if tstamp >= 1.month.ago.to_date
        return "one-month"

    elsif tstamp >= 3.month.ago.to_date
        return "three-months"

    elsif tstamp >= 6.month.ago.to_date
        return "six-months"
    end

    return "over-six-months"

  end

end
