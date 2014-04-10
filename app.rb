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
            @apps << {name: app['name'], service: 'heroku', access: collaborators}
          end
        when /github/i
        end
      end
      render :index
    end
  end
end

module Dashboard::Views
  def layout
    html do
      head { title "Gittip Service Access Dashboard" }
      body do
        h1 "Gittip Service Access Dashboard"
        self << yield
      end
    end
  end

  def index
    @services.each do |service|
      h2 service.name
      unless service.access.nil?
        ul do
          service.access.each do |collab|
            li collab
          end
        end
      end
      unless service.apps.nil?
        case service.name
        when /heroku/i
          service.apps.each do |app|
            h4 app['name']
            app.merge! @apps.select{|a| a[:name] == app['name']}.first
            ul do
              app[:access].each do |collab|
                li collab
              end
            end
          end
        when /github/i
          service.apps.each do |app|
            h4 app['name']
            ul do
              response = @github.get(:path => "/repos/#{app['name']}/teams")
              teams = JSON.parse response.body
              teams.each do |team|
                response = @github.get(:path => "/teams/#{team['id']}/members")
                members = JSON.parse response.body
                members.map{|m| m['login']}.each do |username|
                  li username
                end
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
