module FilterOptions
  extend ActiveSupport::Concern

  private

  def department_options
    User.distinct.pluck(:department).compact.sort
  end

  def saas_category_options
    Saas.distinct.pluck(:category).compact.sort
  end
end
