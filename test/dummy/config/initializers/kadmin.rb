module Dummy
  class User < Kadmin::Auth::User
    def authorized?(_request)
      return true
    end
  end

  class UserStore < Kadmin::Auth::UserStore
    def get(email)
      set(email, Dummy::User.new(email))
      return @store[email.downcase]
    end

    def exists?(_email)
      true
    end
  end
end

Kadmin.config.logger = Rails.logger
Kadmin.config.mount_path = '/admin'

Kadmin::Auth.config.user_class = Dummy::User
Kadmin::Auth.config.user_store_class = Dummy::UserStore

Kadmin::Auth.config.enable!

Kadmin.config.add_navbar_items(
  Kadmin::Navigation::Section.new(
    id: Admin::PeopleController,
    text: 'People',
    links: [
      Kadmin::Navigation::Link.new(text: 'People list', path: -> { Rails.application.routes.url_helpers.admin_people_path }),
      Kadmin::Navigation::Link.new(text: 'Register new person', path: -> { Rails.application.routes.url_helpers.new_admin_person_path })
    ]
  ),
  Kadmin::Navigation::Link.new(text: 'Groups', path: -> { Rails.application.routes.url_helpers.admin_groups_path })
)
