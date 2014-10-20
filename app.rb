require 'active_hash'
require 'excon'
require 'camping'

Camping.goes :Dashboard

module Dashboard::Models
  class Service < ActiveYaml::Base
    set_filename "services"
  end

  class User < ActiveYaml::Base
    set_filename "users"
  end
end

module Dashboard::Controllers
  class Index < R '/'
    def get
      @heroku = Excon.new("https://:#{ENV['HEROKU_API_KEY']}@api.heroku.com", :persistent => true)
      @github = Excon.new("https://#{ENV['GITHUB_TOKEN']}:x-oauth-basic@api.github.com", :persistent => true)
      @balanced = Excon.new("https://auth.balancedpayments.com", :headers => {"Cookie" => "session=#{ENV['BALANCED_COOKIE_SESSION_ID']}"})
      @services = Service.all
      @apps = []

      @services.each do |service|
        case service.name
        when /heroku/i
          service.apps.each do |app|
            app[:access] = []
            response = @heroku.get(:path => "/apps/#{app['name']}/collaborators")
            next if response.status!=200
            collaborators = JSON.parse response.body
            collaborators.each do |collab|
              unless User.find_by_email(collab['email'])
                User.create(:email => collab['email'], :username => '*********')
              end
            end
            collaborators.map! {|collab| User.find_by_email collab['email']}
            app.merge! access: collaborators
          end
        when /github/i
          service.apps.each do |app|
            app[:access] = []
            response = @github.get(:path => "/repos/#{app['name']}/teams")
            next if response.status!=200
            teams = JSON.parse response.body
            teams.each do |team|
              response = @github.get(:path => "/teams/#{team['id']}/members")
              members = JSON.parse response.body
              members.each do |m|
                unless User.find_by_username(m['login'])
                  User.create(:username => m['login'])
                end
                app[:access] << User.find_by_username(m['login'])
              end
            end
          end
        end
      end
      render :index
    end
  end
end

module Dashboard::Views
  def layout
    html do
      head do
        title "Gittip Service Access Dashboard"
        link :rel => "stylesheet",
          :type => "text/css",
          :href => "https://assets-gittipllc.netdna-ssl.com/-/gittip.css"
      end
      body do
        div.hero! do
          h2.top { span "Gittip Service Access Dashboard" }
        end
        div.page! { self << yield }
      end
    end
  end

  def index
    @services.each do |service|
      h1 service.name
      case service.name
      when /heroku/i, /github/i
        # Dynamic service config
        if service.apps
          service.apps.each do |app|
            h2 app['name']
            ul do
              if app[:access]==[]
                li "Service inaccessible"
              else
                app[:access].each do |collab|
                  li collab.username
                end
              end
            end
          end
        end
      else
        # Manual service config
        if service.access
          ul do
            service.access.each do |collab|
              li collab
            end
          end
        end
      end
    end
  end
end
