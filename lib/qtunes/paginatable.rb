module Qtunes
  module Paginatable
    attr_accessor :per_page

    def page(n)
      slice(*[n - 1, 1].map{|i| i * self.per_page }) || []
    end

    def per_page
      @per_page ||= 10
    end
  end
end
