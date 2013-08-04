class JenkinsService < Service
  attr_accessible :project_url

  validates :project_url, presence: true, if: :activated?

  delegate :execute, to: :service_hook, prefix: nil

  after_save :compose_service_hook, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = [project_url, "/build", "?token=#{token}"].join("")
    hook.save
  end

  def commit_status_path sha
    project_url + "/api/xml?xpath=/*/build[action/lastBuiltRevision/SHA1[text()='#{sha}']]&wrapper=builds&depth=1"
  end

  def commit_status sha
    puts commit_status_path(sha)
    response = HTTParty.get(commit_status_path(sha))

    puts response
    if response.code == 200 and response["builds"]
      result = response["builds"]["build"][0]
      status = result["result"].downcase
      failures = ["unstable", "failure", "not_build", "aborted"]
      if failures.include?(status)
        status = "failed"
      end
      [status, result["url"]]
    else
      :error
    end
  end

  def build_page sha
    #placeholder for actual build url
    #it will be updated with real in merge_request.js.coffee
    #after commit_status call
    project_url
  end

  def builds_path
    project_url
  end

  def status_img_path
    project_url + "/badge/icon"
  end

  def title
    'Jenkins'
  end

  def description
    'Jenkins continuous integration server'
  end

  def to_param
    'jenkins'
  end

  def fields
    [
      { type: 'text', name: 'project_url', placeholder: 'http://jenkins.example.com/job/project'}
    ]
  end
end
