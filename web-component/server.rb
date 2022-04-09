require 'sinatra'
require 'json'
require 'rest-client'
require "octokit"

$github_api_token = ENV['GITHUB_API_TOKEN']
$github_secret_token = ENV['SECRET_TOKEN']

post '/payload' do

  # Debug
  puts $github_api_token

  # Only validate secret token if set 
  if !$github_secret_token.nil?
    payload_body = request.body.read
    verify_signature(payload_body)
  end

  github_event = request.env['HTTP_X_GITHUB_EVENT']
  if github_event == "repository"
    request.body.rewind
    parsed = JSON.parse(request.body.read)
    
    action = parsed["action"]
    if(action == 'created') # we only want to react to creation even
        
        repo_name = parsed["repository"]["full_name"]
        client = Octokit::Client.new(:access_token => $github_api_token)

        # TODO: there can be a use-case where the repo is created from a template and thus could already a branch which is not named "main"
        # 1- get repo info (using client.repository(repo_name))
        # 2- get the branch name
        # 3- if the branch already exist, no need to create a file
        # 4- we can then apply the protection to this branch

        # Creates a file, which forces the creation of a default branch, name "main" (it's an organization setting)
        client.create_content(repo_name,'README.md',"Adding a readme file", "Hello GitHub!")
        
        # Enable branch protection
        hash = {
            enforce_admins: false,
            required_pull_request_reviews: {
                dismissal_restrictions: {},
                dismiss_stale_reviews: false,
                require_code_owner_reviews: false
            }
        }
        client.protect_branch(repo_name, 'main', hash) # the default branch here is "main" but we could detect it

        # Creates an issue
        client.create_issue(repo_name,"Protection has been added","@lgmorand")
    end

  end


end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end