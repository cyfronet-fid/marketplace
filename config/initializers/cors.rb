# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %r(/\Alocalhost:\d{1024,65535}\z/),
            %r{/\Ahttps://search-\d{1,15}\.docker-fid\.grid\.cyf-kr\.edu\.pl\z/},
            %r(/\Ahttps://marketplace-\d{1,15}\.docker-fid\.grid\.cyf-kr\.edu\.pl/\z/),
            "https://aai.eosc-portal.eu/",
            "https://beta.marketplace.eosc-portal.eu/",
            "https://beta.search.marketplace.eosc-portal.eu/"

    resource "*", headers: :any, methods: [:get, :post, :patch, :put, :delete, :options, :head]
  end
end