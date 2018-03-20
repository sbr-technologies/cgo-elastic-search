module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
#    include Elasticsearch::Model::Callbacks
    # Customize the index name
#    after_save() { __elasticsearch__.update_document }
#    index_name [Rails.application.engine_name, Rails.env].join('_')

    # Set up index configuration and mapping
    #
    settings index: { number_of_shards: 2, number_of_replicas: 0 } do
        mapping _source: { excludes: ['attachment', 'last_name', 'status'] } do
#        mapping do
          indexes :id, type: 'integer'
          indexes :name, type: 'multi_field' do
            indexes :name
            indexes :raw, analyzer: 'keyword'
          end
          indexes :updated_at, type: 'date'
          indexes :created_at, type: 'date'
          indexes :attachment, type: 'attachment'
        end
      end

    def as_indexed_json(options={})
    {
      last_name:              last_name,
      created_at: created_at,
      updated_at: updated_at,
      availability_date: availability_date,
      type_of_applicant: type_of_applicant,
      security_clearance: security_clearance,
      education_level: education_level,
      branch_of_service: branch_of_service,
      us_citizen: us_citizen,
      willing_to_relocate: willing_to_relocate,
      email: email,
      status: status,
      addresses: addresses.as_json(only: [:street_address1, :street_address2, :city, :state, :zip, :phone, :mobile]),
      resume: resume.as_json(only: [:id]),
      registrations: registrations.as_json(only: [:jobfair_id]),
      attachment: attachment,
      name: name
    }
    end

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(query, options={})

      # Prefill and set the filters (top-level `filter` and `facet_filter` elements)
      #
      __set_filters = lambda do |key, f|

        @search_definition[:filter][:and] ||= []
        @search_definition[:filter][:and] |= [f]

      end

      @search_definition = {
        query: {},

        highlight: {
          pre_tags: ['<em class="label label-highlight">'],
          post_tags: ['</em>'],
          fields: {
            title: { number_of_fragments: 0 },
            abstract: { number_of_fragments: 0 },
            content: { fragment_size: 50 }
          }
        },

        filter: {}
      }

      unless query.blank?
        @search_definition[:query] = {
          bool: {
            should: [
              { query_string: {
                  query: query,
                  fields: ['first_name','email', 'name', 'attachment', 'street_address1', 'street_address2', 'city', 'state', 'zip', 'phone', 'mobile']
                }
              }
            ]
          }
        }
      else
        @search_definition[:query] = { match_all: {} }
        @search_definition[:sort] = { name: 'desc' }
      end

      f = { term: { 'status' => 'active' } }
      __set_filters.(:status, f)
     

      unless options[:last_name].to_s.blank?
        f = { term: { 'last_name' => options[:last_name].to_s.downcase } }

        __set_filters.(:last_name, f)
      end

      unless options[:state].to_s.blank?
        f = { terms: { 'state' =>options[:state].flatten} }
        __set_filters.(:state, f)
      end

      unless options[:security_clearance].to_s.blank?
        f = { terms: { 'security_clearance' => options[:security_clearance].flatten} }
        __set_filters.(:security_clearance, f)
#        __set_filters.(:last_name, f)
      end

      unless options[:type_of_applicant].to_s.blank?
        f = { terms: { 'type_of_applicant' => options[:type_of_applicant].flatten} }
        __set_filters.(:type_of_applicant, f)
      end
#
      unless options[:branch_of_service].to_s.blank?
        f = { terms: { 'branch_of_service' => options[:branch_of_service].flatten} }
        __set_filters.(:branch_of_service, f)
      end

      unless options[:education_level].to_s.blank?
        f = { terms: { 'education_level' => options[:education_level].flatten} }
        __set_filters.(:education_level, f)
      end

      unless options[:how_many].to_s.blank?
        f = { range: { 
                        updated_at:{
                          gte: options[:how_many].months.ago.to_date.to_s(:db)
#                          lte: Date.today.to_s(:yyyymmdd).to_i
                        }
                      } 
                      
            }
        __set_filters.(:education_level, f)
      end

      
      unless options[:willing_to_relocate].blank?
        f = { term: { 'willing_to_relocate' =>options[:willing_to_relocate]} }

        __set_filters.(:willing_to_relocate, f)
      end
      
      unless options[:job_fair_registrations].to_s.blank?
        f = { term: { 'jobfair_id' =>options[:job_fair_registrations]} }

        __set_filters.(:jobfair_id, f)
      end

      logger.debug(@search_definition.inspect)

      __elasticsearch__.search(@search_definition)
    end
  end

  def name
    [first_name, initial, last_name].select {|x| not x.nil?}.map {|x| x.strip}.join(" ").titleize
  end 

  def attachment
    if !attached_resume.nil? && File.exist?(attached_resume.path.to_s)
      Base64.encode64(open(attached_resume.path) { |file| file.read })
    else
      ''
    end
  end
end
