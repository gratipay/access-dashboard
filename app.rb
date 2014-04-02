require 'camping'
require 'active_hash'

Camping.goes :App

module App:Models
  class Service < ActiveYaml::Base
    include ActiveHash::Associations
    has_many :users

    set_filename "services"
  end

  class User < ActiveYaml::Base
    include ActiveHash::Associations
    belongs_to :service

    set_filename "users"
  end
end

module App::Controllers
  class Index
    def get
      @services = Service.all
      render :index
    end
  end
end

module App::Views
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
      p service.access.sort.join ', '
    end
  end
end
