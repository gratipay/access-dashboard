require 'camping'
require 'yaml'

Camping.goes :App

def config
  YAML.load_file("config.yml")
end

module App:Models
  class Service
    def self.all
      config['services'].keys
    end
  end

  class User
    def self.all
      config['users']
    end
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
      h2 service
    end
  end
end
