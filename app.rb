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
      @heroku = Excon.new("https://:#{ENV['HEROKU_API_KEY']}@api.heroku.com")
      @github = Excon.new("https://#{ENV['GITHUB_TOKEN']}:x-oauth-basic@api.github.com")
      @services = Service.all
      @apps = []

      @services.each do |service|
        case service.name
        when /heroku/i
          service.apps.each do |app|
            response = @heroku.get(:path => "/apps/#{app['name']}/collaborators").body
            collaborators = JSON.parse response
            collaborators.map! {|collab| collab['email'] }
            app.merge! access: collaborators
          end
        when /github/i
          service.apps.each do |app|
            app[:access] = []
            response = @github.get(:path => "/repos/#{app['name']}/teams")
            teams = JSON.parse response.body
            teams.each do |team|
              response = @github.get(:path => "/teams/#{team['id']}/members")
              members = JSON.parse response.body
              members.map{|m| m['login']}.each do |username|
                app[:access] << username
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
          :href => "https://assets-gittipllc.netdna-ssl.com/12.3.3/gittip.css"
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
      unless service.access.nil?
        ul do
          service.access.each do |collab|
            li collab
          end
        end
      end
      unless service.apps.nil?
        case service.name
        when /heroku/i, /github/i
          service.apps.each do |app|
            h2 app['name']
            ul do
              app[:access].each do |collab|
                li collab
              end
            end
          end
        else
          nil
        end
      end
    end
  end
end
