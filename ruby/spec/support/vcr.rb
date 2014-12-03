require 'vcr'
require 'rspec'

ACCESS_TOKEN = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
FORM_ID = 0000000
INACCESSIBLE_FORM_ID = 0000001
DELETE_SUBMISSION_FORM = 0000000
UPLOAD_FORM_ID = 0000000
UPLOAD_FIELD_IDS = 00000000
LOGO_PATH = File.join(File.dirname(__FILE__), '../fs-logo.png')
SUBMIT_FORM_ID = DELETE_SUBMISSION_FORM
CREATE_FIELD_FORM_ID = DELETE_SUBMISSION_FORM
SUBMISSION_DETAILS_ID = 000000000
SUBMISSION_DETAILS_FORM_ID = 0000000
EDIT_SUBMISSION_FIELD_ID = 00000000
EDIT_SUBMISSION_ARRAY_FIELD_ID = 00000000

VCR.configure do |c|
    c.cassette_library_dir = 'spec/vcr'
    c.hook_into :webmock # or :fakeweb
    c.filter_sensitive_data('<ACCESS_TOKEN>') { ACCESS_TOKEN }
    c.filter_sensitive_data('<FORM_ID>') { SUBMIT_FORM_ID }
    c.filter_sensitive_data('<INACCESSIBLE_FORM_ID>') { INACCESSIBLE_FORM_ID }
    c.filter_sensitive_data('<SUBMISSION_DETAILS_ID>') { SUBMISSION_DETAILS_ID }
    c.filter_sensitive_data('<UPLOAD_FORM_ID>') { UPLOAD_FORM_ID }
    c.filter_sensitive_data('<UPLOAD_FIELD_IDS>') { UPLOAD_FIELD_IDS }
    c.filter_sensitive_data('<LOGO_PATH>') { LOGO_PATH }
    c.filter_sensitive_data('<SUBMISSION_DETAILS_FORM_ID>') { SUBMISSION_DETAILS_FORM_ID }
    c.filter_sensitive_data('<DELETE_SUBMISSION_FORM>') { DELETE_SUBMISSION_FORM }
    c.filter_sensitive_data('<EDIT_SUBMISSION_FIELD_ID>') { EDIT_SUBMISSION_FIELD_ID }
    c.filter_sensitive_data('<EDIT_SUBMISSION_ARRAY_FIELD_ID>') { EDIT_SUBMISSION_ARRAY_FIELD_ID }
    c.default_cassette_options = { record: :new_episodes }
    c.configure_rspec_metadata!
end
