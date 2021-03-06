require 'mechanize'
require 'httparty'

module NationSync
  class Auth
    attr_reader :access_token, :session_id
    attr_accessor :domain, :email, :password
    
    def initialize(domain, email, password)
      @domain   = domain
      @email    = email
      @password = password
    end
    
    def authenticate!
      agent = Mechanize.new
      # Disallow redirect
      agent.redirect_ok = false

      page = agent.get("https://#{@domain}.nationbuilder.com/admin/theme_tool_api/auth")

      signin = page.forms.select {|f| f.action == "/admin/theme_tool_api/auth" }.first
      email    = signin.field "user_session[email]"
      password = signin.field "user_session[password]"

      email.value    = @email
      password.value = @password

      # Submit the form
      resp = signin.submit()
      # Returns a redirect we have to follow to finish up the authorization.
      auth = agent.get resp.header["Location"]
      # Following the auth redirect we get another redirect to:
      # app://com.nationbuildertheme/index.html?code=[blah]"
      redirect = auth.header["Location"]
      # Extract the code from the redirect
      code = redirect.match(/code=([a-f0-9]+)/)[1]
      # And then exchange the code for an access_token.
      resp = HTTParty.get "https://southforward.nationbuilder.com/admin/theme_tool_api/exchange?code=#{code}"
      body = JSON.parse(resp.body)
      @access_token = body["access_token"]
      #puts "access_token: #{access_token}"
      # Also grab the session ID since we need that.
      @session_id = agent.cookie_jar.select {|c| c.name == "_nbuild_session" }.first.value
      #puts "session_id: (_nbuild_session) #{session_id}"
      return true
    end
    
    
  end#API
end#NationSync
