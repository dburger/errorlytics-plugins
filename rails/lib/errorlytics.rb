require 'base64'
require 'digest/sha1'
require 'net/http'

module Errorlytics

  def self.included(base)
    # no, base.rescue_from ActionController::RoutingError won't work
    # base.rescue_from ActionController::RoutingError, :with => :errorlytics_rescue
    if base.instance_methods.include?('rescue_action_in_public') &&
        !base.instance_methods.include?('rescue_action_in_public_without_errorlytics')
      base.alias_method_chain(:rescue_action_in_public, :errorlytics)
    end
  end

  class << self
    attr_accessor :url, :secret_key, :account_id, :website_id

    def url
      @url ||= 'http://www.errorlytics.com'
    end

    def account_url
      URI.parse("#{url.chomp('/')}/accounts/#{account_id}/websites/#{website_id}/errors")
    end
  end

  def rescue_action_in_public_with_errorlytics(exc)
    case exc
      when ActionController::RoutingError
        check_with_errorlytics(exc)
      else
        rescue_action_in_public_without_errorlytics(exc)
    end
  end

  def check_with_errorlytics(exc)
    response = get_errorlytics_response
    rescue_action_in_public_without_errorlytics(exc) and return if !response
    response = response.body
    response_code = (/<response-code>(.+)<\/response-code>/ =~ response) ?
        $1.to_i : nil
    uri = (/<uri>(.+)<\/uri>/ =~ response) ? $1 : nil
    if response_code && uri
      redirect_to(uri, :status => response_code)
    else
      rescue_action_in_public_without_errorlytics(exc)
    end
  end

  def create_errorlytics_data(path)
    data = 'error[http_host]=' + CGI.escape(request.host)
    data << '&error[request_uri]=' + CGI.escape(request.request_uri)
    data << '&error[http_user_agent]=' + CGI.escape(request.headers['User-Agent'])
    data << '&error[remote_addr]=' + CGI.escape(request.remote_ip)
    data << '&error[http_referer]=' + CGI.escape(request.headers['Referer'] || '')
    occurred_at = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    data << '&error[client_occurred_at]=' + CGI.escape(occurred_at)
    signature = Digest::SHA1.hexdigest(occurred_at + path + Errorlytics.secret_key)
    data << '&signature=' + CGI.escape(signature)
    data << '&error[fake]=false'
    data << '&format=xml'
  end

  # returns a Net::HTTPResponse or nil, body is in response.body
  def get_errorlytics_response
    url = Errorlytics.account_url
    Net::HTTP.start(url.host, url.port) do |http|
      http.open_timeout = 3
      http.read_timeout = 6
      # 'Content-Type' => 'application/x-www-form-urlencoded' by default
      headers = {
        'Accept' => 'text/xml, application/xml'
      }
      data = create_errorlytics_data(url.path)
      begin
        response = http.post(url.path, data, headers)
      rescue TimeoutError => exc
        nil
      end
    end
  end

end
