require "formstack/api/version"

module Formstack
  class API
    require 'httparty'
    require 'json'
    require 'uri'

    include HTTParty

    FIELD_TYPES = [
      'text',
      'textarea',
      'name',
      'address',
      'email',
      'phone',
      'creditcard',
      'datetime',
      'file',
      'number',
      'select',
      'radio',
      'checkbox',
      'matrix',
      'richtext',
      'embed',
      'product',
      'section',
    ]

    def initialize(access_token)
      @access_token = access_token
      @api_url = 'https://www.formstack.com/api/v2/'
    end

    def request(end_point, verb='GET', arguments={})
      arguments.merge!(headers: { "Authorization" => "Bearer #{@access_token }"})

      valid_verbs = %w(GET PUT POST DELETE)

      if end_point.empty?
        raise 'Missing End Point'
      end

      verb.upcase!

      unless valid_verbs.include?(verb)
        raise 'Wrong verb'
      end

      url = "#{@api_url}#{end_point}"

      case verb
      when 'GET'
        response = self.class.get(url, arguments )
      when 'POST'
        response = self.class.post(url, arguments )
      when 'PUT'
        response = self.class.put(url, arguments )
      when 'DELETE'
        response = self.class.delete(url, arguments )
      end

      if response.code < 200 || response.code >= 300
        raise 'Bad token'
      end

      body = JSON.parse(response.body)
      return body
    end

    def forms(organized_folders=false)
      organized_folders = organized_folders ? 1 : 0
      response = request("form.json#{query(folders: organized_folders)}", 'GET')
      response['forms']
    end

    def form_details(form_id)
      is_numeric?(form_id)

      request("form/#{form_id}", 'GET');
    end

    def copy_form(form_id)
      is_numeric?(form_id)

      request("form/#{form_id}/copy", 'POST');
    end

    def form_submissions(form_id, encryption_password='', min_time='',
                         max_time='', search_fields=[], search_fields_values=[],
                         page_number=1, per_page=25, sort='DESC', data=false,
                         expand_data=false)

      is_numeric?(form_id)

      unless min_time.empty?
        begin
          Time.parse(min_time)
        rescue Exception => e
          raise 'Invalid value for minTime parameter'
        end
      end

      unless max_time.empty?
        begin
          Time.parse(max_time)
        rescue Exception => e
          raise 'Invalid value for maxTime parameter'
        end
      end

      raise 'You must have a one to one relationship' unless search_fields.size == search_fields_values.size

      search_fields.each do |id|
        raise 'Field IDs must be numeric' unless id.is_a? Numeric
      end

      if !per_page.is_a? Numeric
        raise 'The perPage value must be numeric'
      elsif per_page < 1 || per_page > 100
        raise 'You can only retrieve a minimum of 1 and maximum of 100 submissions per request'
      end

      raise 'The pageNumber value must be numeric' unless page_number.is_a? Numeric

      raise 'The sort parameter must be ASC or DESC' unless sort == 'ASC' || sort == 'DESC'


      end_point = "form/#{form_id}/submission.json"

      sort.upcase!

      arguments = {
          'encryption_password'   =>  encryption_password,
          'min_time'              =>  min_time,
          'max_time'              =>  max_time,
          'page'                  =>  page_number,
          'per_page'              =>  per_page,
          'sort'                  =>  sort,
          'data'                  =>  data,
          'expand_data'           =>  expand_data,
      }

      arguments.delete('data') unless data
      arguments.delete('expand_data') unless expand_data

      arguments = API.clean_arguments(arguments)

      search_fields.each_with_index do |field, idx|
        arguments["search_field_#{idx}"] = search_field_ids[idx]
        arguments["search_value_#{idx}"] = search_field_values[idx]
      end

      response = request(end_point, 'GET', { body: arguments })
      response['submissions']
    end

    def submit_form(form_id,
                    field_ids = [],
                    field_values = [],
                    timestamp = '',
                    user_agent = '',
                    ip_address = '',
                    payment_status = '',
                    read = false)

      arguments = {
        'timestamp' => timestamp,
        'user_agent' => user_agent,
        'remote_addr' => ip_address,
        'payment_status' => payment_status,
        'read' => read ? 1 : 0
      }

      is_numeric?(form_id)

      unless timestamp.empty?
        begin
          Time.parse(timestamp)
        rescue Exception => e
          raise 'You must use a valid Date/Time string formatted in YYYY-MM-DD HH:MM:SS'
        end
      end

      raise 'There must be a one-to-one relationship between Field IDs and their values' unless field_ids.size == field_values.size

      arguments = API.clean_arguments(arguments)
      arguments = API.add_field_data(arguments, field_ids, field_values)

      response = request("form/#{form_id}/submission.json", 'POST', { body: arguments } )
    end

    def get_submission_details(submission_id, encryption_password = '')
      arguments = {}
      arguments['encryption_password'] = encryption_password unless encryption_password.empty?

      raise 'Submission ID must be numeric' unless submission_id.is_a? Numeric

      response = request("submission/#{submission_id}.json", 'GET', arguments)
    end

    def edit_submission_data(submission_id,
                             field_ids = [],
                             field_values = [],
                             timestamp = '',
                             user_agent = '',
                             ip_address = '',
                             payment_status = '',
                             read = false)

      arguments = {
        'timestamp' => timestamp,
        'user_agent' => user_agent,
        'remote_addr' => ip_address,
        'payment_status' => payment_status,
        'read' => read ? 1 : 0
      }

      raise 'Submission ID must be numeric' unless submission_id.is_a? Numeric

      unless timestamp.empty?
        begin
          Time.parse(timestamp)
        rescue Exception => e
          raise 'You must use a valid Date/Time string formatted in YYYY-MM-DD HH:MM:SS'
        end
      end

      arguments = API.clean_arguments(arguments)
      arguments = API.add_field_data(arguments, field_ids, field_values)

      request("submission/#{submission_id}.json", 'PUT', { body: arguments } )
    end

    def delete_submission(submission_id)
      raise 'Submission ID must be numeric' unless submission_id.is_a? Numeric

      request("submission/#{submission_id}", 'DELETE' )
    end

    def create_field(form_id, field_type = '', label = '', hide_label = false,
                     description = '', use_callout = false,
                     field_specific_attributes = [], default_value = '',
                     options = [], options_values = [], required = false,
                     read_only = false, hidden = false, unique = false,
                     column_span = nil, sort = nil)

      is_numeric?(form_id)

      raise 'Provided Field Type is not in the list of known Field types' unless FIELD_TYPES.include? field_type

      arguments = {}

      arguments['field_type'] = field_type
      arguments['label'] = label unless label.empty?
      arguments['hide_label'] = 1 if hide_label
      arguments['description'] = description unless description.empty?
      arguments['description_callout'] = 1 if use_callout
      arguments['default_value'] = default_value unless default_value.empty?
      arguments['options'] = options unless options.empty?
      arguments['options_values'] = options_values unless options_values.empty?
      arguments['required'] = 1 if required
      arguments['read_only'] = 1 if read_only
      arguments['hidden'] = 1 if hidden
      arguments['unique'] = 1 if unique
      arguments['colspan'] = column_span unless column_span.nil?
      arguments['sort'] = sort unless sort.nil?

      request("form/#{form_id}/field", 'POST', { body: arguments } )
    end

    private

    def self.add_field_data(arguments, field_ids, field_values)

      if field_ids.empty?
        raise 'There must be a one-to-one relationship between Field IDs and their values' if field_ids.size != field_values.size
      end

      field_ids.each_with_index do |id, i|
        raise 'Field IDs must be numeric' unless id.is_a? Numeric
        arguments["field_#{field_ids[i]}"] = field_values[i]
      end

      arguments
    end

    def self.clean_arguments(args)
      arguments = {}

      args.each_pair do |key, value|
        arguments[key] = value unless value == ''
      end

      arguments
    end

    def is_numeric?(form_id)
      unless form_id.is_a? Numeric
        raise 'Form ID must be numeric'
      end
    end

    def query(args)
      query = URI.encode_www_form(args)
      "?#{query}"
    end
  end
end
