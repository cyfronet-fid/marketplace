# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(%r{\Ahttp://localhost:([1-9]|1[0-5]|10(2[4-9]|[3-9]\d)|1[1-9]\d{2}|[2-9]\d{3}|[1-5]\d{4}|6([0-4]\d{3}|5([0-5][0-3][0-5])))\z},
            %r{\Ahttps://search-([1-9]|1[0-5])\.docker-fid\.grid\.cyf-kr\.edu\.pl\z},
            %r{\Ahttps://(integration\.)marketplace-([1-9]|1[0-5])\.docker-fid\.grid\.cyf-kr\.edu\.pl\z},
            %r{\Ahttps://(integration\.)?core-proxy\.sandbox\.eosc-beyond\.eu\z"},
            %r{\Ahttps://access\.eosc\.pl\z},
            "https://aai.eosc-portal.eu",
            "https://beta.marketplace.eosc-portal.eu/",
            "https://beta.search.marketplace.eosc-portal.eu/")

    resource "*", headers: :any, methods: [:get, :post, :patch, :put, :delete, :options, :head]
  end
end