require_relative '../lib/formstack/api'
require "base64"

RSpec.describe Formstack::API do

  let(:access_token) { ACCESS_TOKEN }
  let(:invalid_form_id) { 1234 }
  let(:inaccessible_form_id) { INACCESSIBLE_FORM_ID }
  let(:delete_submission_form) { DELETE_SUBMISSION_FORM }
  let(:submit_form_id) { SUBMIT_FORM_ID }
  let(:upload_form_id) { UPLOAD_FORM_ID }
  let(:upload_field_ids) { [UPLOAD_FIELD_IDS] }
  let(:logo_path) { LOGO_PATH }
  let(:create_field_form_id) { CREATE_FIELD_FORM_ID }
  let(:submission_details_id) { SUBMISSION_DETAILS_ID }
  let(:submission_details_form_id) { SUBMISSION_DETAILS_FORM_ID }
  let(:edit_submission_field_id) { EDIT_SUBMISSION_FIELD_ID }
  let(:edit_submission_array_field_id) { EDIT_SUBMISSION_ARRAY_FIELD_ID }

  subject(:wrapper) { Formstack::API.new(access_token) }

  describe '#request', :vcr do

    it 'raises an exception when endpoint is empty' do
      expect{wrapper.request('')}.to raise_exception('Missing End Point')
    end

    it 'raises an exception with a bad verb' do
      expect{wrapper.request('/test/endpoint', 'FAIL')}.to raise_exception('Wrong verb')
    end

    let(:access_token) { 'fail' }
    it 'raises an exception with a bad token' do
      expect{wrapper.request('form.json')}.to raise_exception('Bad token')
    end
  end

  describe '#forms', :vcr do
    it 'responds with no folders by default' do
      forms = wrapper.forms
      expect(forms.class).to eq(Array)
    end

    it 'gets folders when asked' do
      folders = wrapper.forms(true)
      expect(folders.class).to eq(Hash)
    end
  end

  describe '#form_details', :vcr do
    it 'reads a form name' do
      form = wrapper.form_details(submit_form_id)
      expect(form['name']).to eq('Test Form')
    end

    it 'raises an error if form id is not a number' do
      expect{wrapper.form_details('TEXT')}.to raise_exception('Form ID must be numeric')
    end

    it 'responds with an error if form id doesnt exist' do
      response = wrapper.form_details(invalid_form_id)
      expect(response['status']).to eq('error')
      expect(response['error']).to eq('The form was not found')
    end

    it 'responds with an error if you dont have access to form' do
      response = wrapper.form_details(inaccessible_form_id)
      expect(response['status']).to eq('error')
      expect(response['error']).to eq('You do not have high enough permissions for this form.')
    end
  end

  describe '#copy_form', :vcr do
    it 'adds COPY at the end of the form name' do
      form = wrapper.form_details(submit_form_id)
      copied_form = wrapper.copy_form(submit_form_id)
      expect(copied_form['name']).to match(/^#{form['name']} - COPY/)
    end

    it 'raises an error if form id is not a number' do
      expect{wrapper.copy_form('TEXT')}.to raise_exception('Form ID must be numeric')
    end

    it 'raises an error if form id is invalid' do
      response = wrapper.copy_form(invalid_form_id)
      expect(response['status']).to eq('error')
      expect(response['error']).to eq('A valid form id was not supplied')
    end
  end

  describe '#form_submissions', :vcr do
    it 'gets submissions default' do
      form = wrapper.form_details(submit_form_id)
      submissions_count = form['submissions'].to_i > 25 ? 25 : form['submissions'].to_i

      submissions = wrapper.form_submissions(submit_form_id)
      expect(submissions_count).to eq(submissions.count)
    end

    it 'raises an error if form id isnt numeric' do
      expect{wrapper.form_submissions('TEXT')}.to raise_exception('Form ID must be numeric')
    end

    it 'raises an error if min time is invalid' do
      expect{wrapper.form_submissions(submit_form_id, '', 'BAD')}.to raise_exception('Invalid value for minTime parameter')
    end

    it 'raises an error if max time is invalid' do
      expect{wrapper.form_submissions(submit_form_id, '', '', 'BAD')}.to raise_exception('Invalid value for maxTime parameter')
    end

    it 'raises an error for a search mismatch' do
      field_ids = [1, 2, 3]
      field_values = ['test-1', 'test-2']
      expect{wrapper.form_submissions(submit_form_id, '', '', '', field_ids, field_values)}.to raise_exception('You must have a one to one relationship')
    end

    it 'raises an error for a search mismatch reversed' do
      field_ids = [1, 2]
      field_values = ['test-1', 'test-2', 'test-3']
      expect{wrapper.form_submissions(submit_form_id, '', '', '', field_ids, field_values)}.to raise_exception('You must have a one to one relationship')
    end

    it 'raises an error if field ids are not numeric' do
      field_ids = [1, 'two']
      field_values = ['test-1', 'test-2']
      expect{wrapper.form_submissions(submit_form_id, '', '', '', field_ids, field_values)}.to raise_exception('Field IDs must be numeric')
    end

    it 'raises an error if per_page is not numeric' do
      expect{wrapper.form_submissions(submit_form_id, '', '', '', [], [], 1, 'fail')}.to raise_exception('The perPage value must be numeric')
    end

    it 'raises an error if requests per page are less than 1' do
      expect{wrapper.form_submissions(submit_form_id, '', '', '', [], [], 1, 0)}.to raise_exception('You can only retrieve a minimum of 1 and maximum of 100 submissions per request')
    end

    it 'raises an error if requests per page are more than 100' do
      expect{wrapper.form_submissions(submit_form_id, '', '', '', [], [], 1, 101)}.to raise_exception('You can only retrieve a minimum of 1 and maximum of 100 submissions per request')
    end

    it 'raises an error if page_number is not numeric' do
      expect{wrapper.form_submissions(submit_form_id, '', '', '', [], [], 'fail')}.to raise_exception('The pageNumber value must be numeric')
    end

    it 'raises an error if page number is not working' do
      page1 = wrapper.form_submissions(submit_form_id, '', '', '', [], [], 1, 1, 'DESC')
      page2 = wrapper.form_submissions(submit_form_id, '', '', '', [], [], 2, 1, 'DESC')

      expect(page1).not_to eq(page2)
    end

    it 'raises an error if the sort parameter is invalid' do
      expect{wrapper.form_submissions(submit_form_id, '', '', '', [], [], 1, 100, 'fail')}.to raise_exception('The sort parameter must be ASC or DESC')
    end

    it 'returns no data by default' do
      submission = wrapper.form_submissions(submit_form_id).first

      expect(submission.include?('data')).to eq(false)
    end

    it 'returns data if specified' do
      submission = wrapper.form_submissions(submit_form_id, '', '', '', [], [], 1, 100, 'DESC', true).first

      expect(submission.include?('data')).to eq(true)
    end

  end

  describe '#submit_form', :vcr do
    let(:submit_form_field_ids) { [28705506, 28706107, 28706112] }
    let(:submit_form_field_values) { ['short-answer-test', {'first' => 'first-test', 'last' => 'last-test'}, 'this is a long answer field'] }

    it 'creates a submission into a form' do
      response = wrapper.submit_form(submit_form_id, submit_form_field_ids, submit_form_field_values)
      expect(response['form'].to_i).to eq(submit_form_id)

      response['data'].each do |row|
        value = submit_form_field_values.to_a[submit_form_field_ids.index(row['field'].to_i)]
        if value.class == Hash
          clean_hash = {}
          row['value'].to_s.split(/\n/).each do |a|
            key, val = a.split(' = ')
            clean_hash[key] = val
          end
          expect(clean_hash).to eq(value)
        else
          expect(row['value']).to eq(value)
        end
      end
    end

    it 'raises an error if the form id is non numeric' do
      expect{wrapper.submit_form('fail')}.to raise_exception('Form ID must be numeric')
    end

    it 'raises an eror if the timestamp format is invalid' do
      expect{wrapper.submit_form(submit_form_id, [], [], 'this is not a valid date/time string')}.to raise_exception('You must use a valid Date/Time string formatted in YYYY-MM-DD HH:MM:SS')
    end

    it 'raises an error for a data array mismatch' do
      field_ids = [1, 2, 3]
      field_values = ['a', 'b']
      expect{wrapper.submit_form(submit_form_id, field_ids, field_values)}.to raise_exception('There must be a one-to-one relationship between Field IDs and their values')
    end

    it 'raises an error for a data array mismatch reversed' do
      field_ids = [1, 2]
      field_values = ['a', 'b', 'c']
      expect{wrapper.submit_form(submit_form_id, field_ids, field_values)}.to raise_exception('There must be a one-to-one relationship between Field IDs and their values')
    end

    it 'raises an error if field ids are not numeric' do
      field_ids = ['one']
      field_values = ['a']
      expect{wrapper.submit_form(submit_form_id, field_ids, field_values)}.to raise_exception('Field IDs must be numeric')
    end

    it 'uploads an image' do
      logo_data = File.open(logo_path, 'rb') { |file| file.read }
      upload_field_values = [[logo_data, 'fs-logo.png']]

      upload_field_values.each_with_index do |field, idx|
        upload_field_values[idx] = "#{upload_field_values[idx][1]};#{Base64.encode64(field[0])}"
      end

      response = wrapper.submit_form(upload_form_id, upload_field_ids, upload_field_values)

      expect(response['data']).not_to be_empty

      response['data'].each_with_index do |row, idx|
        expect(row['field'].to_i).to eq(upload_field_ids[idx])
        expect(row['value']).not_to be_empty
      end
    end
  end

  describe '#get_submission_details', :vcr do

    it 'gets the right submission from the right form' do
      submission = wrapper.get_submission_details(submission_details_id)
      expect(submission['form'].to_i).to eq(submission_details_form_id)
    end

    it 'raises an error if submission id is not numeric' do
      expect{wrapper.get_submission_details('FAIL')}.to raise_exception('Submission ID must be numeric')
    end
  end

  describe '#edit_submission_data', :vcr do

    let(:value) { "test#{Time.now}" }
    let(:hash_value) { { 'first' => "#{value}-first", 'last' => "#{value}-last" } }
    let(:edit_submission_id) { get_editable_submission_id }

    it 'edits a submission succesfully' do

      response = wrapper.edit_submission_data(edit_submission_id,
                                              [edit_submission_field_id, edit_submission_array_field_id],
                                              [value, hash_value])

      expect(response['success'].to_i).to eq(1)
      expect(response['id'].to_i).to eq(edit_submission_id)

      submission = wrapper.get_submission_details(edit_submission_id)

      submission['data'].each do |row|
        if row['field'] == edit_submission_field_id
          expect(row['value']).to eq(value)
        elsif row['field'] == edit_submission_array_field_id
          expect(row['value']).to eq(hash_value)
        end
      end
    end

    it 'raises an exception when the submission id is non numeric' do
      expect{ wrapper.edit_submission_data('FAIL') }.to raise_exception('Submission ID must be numeric')
    end

    it 'raises an exception with a bad timestamp' do
      expect{
        wrapper.edit_submission_data(edit_submission_id, [], [], 'Bad Date String')
      }.to raise_exception('You must use a valid Date/Time string formatted in YYYY-MM-DD HH:MM:SS')
    end

    it 'raises an exception when data array and ids don\'t match' do
      expect{
        wrapper.edit_submission_data(edit_submission_id, [1,2,3], ['test-1', 'test-2'], 'Bad Date String')
      }.to raise_exception('You must use a valid Date/Time string formatted in YYYY-MM-DD HH:MM:SS')
    end

    it 'raises an exception when data array and ids don\'t match reversed' do
      expect{
        wrapper.edit_submission_data(edit_submission_id, [1,2], ['test-1', 'test-2', 'test-3'], 'Bad Date String')
      }.to raise_exception('You must use a valid Date/Time string formatted in YYYY-MM-DD HH:MM:SS')
    end

    it 'raises an exception if fields are non numeric' do
      expect{
        wrapper.edit_submission_data(edit_submission_id, ['fail'], ['test-1'])
      }.to raise_exception('Field IDs must be numeric')
    end
  end

  describe '#delete_submission', :vcr do
    it 'deletes a submission' do
      submission_to_delete = get_editable_submission_id
      response = wrapper.delete_submission(submission_to_delete)
      expect(response['success'].to_i).to eq(1)
      expect(response['id'].to_i).to eq(submission_to_delete)
    end

    it 'raises an exception with a non numeric id' do
      expect{wrapper.delete_submission('FAIL')}.to raise_exception('Submission ID must be numeric')
    end
  end

  describe '#create_field', :vcr do
    it 'creates a text field' do
      field_name = "Test Field #{Time.now}"
      field = wrapper.create_field(create_field_form_id, 'text', field_name)

      expect(field['label']).to match(/Test Field/)
      expect(field['type']).to eq('text')
    end

    it 'creates a field with embeded code' do
      attributes = { 'text' => '<script type="text/javascript">alert(\'Woop there it is \');</script>' }

      field = wrapper.create_field(create_field_form_id, 'embed', '', false, '', false, attributes)

      expect(field['type']).to eq('embed')
    end
  end

  # describe '#', :vcr => { :record => :all } do

  def get_editable_submission_id
    wrapper.form_submissions(delete_submission_form, '', '', '', [], [], 1, 100, 'ASC').first['id'].to_i
  end
end
