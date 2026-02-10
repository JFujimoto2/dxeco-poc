require "csv"

class SaasImportService
  def initialize(file_path)
    @file_path = file_path
  end

  def call
    result = { success_count: 0, error_count: 0, errors: [] }

    CSV.foreach(@file_path, headers: true, encoding: "BOM|UTF-8").with_index(2) do |row, line_num|
      if Saas.exists?(name: row["name"])
        result[:error_count] += 1
        result[:errors] << "#{line_num}行目: SaaS '#{row['name']}' は既に存在します"
        next
      end

      saas = Saas.new(
        name: row["name"],
        category: row["category"],
        url: row["url"],
        admin_url: row["admin_url"],
        description: row["description"],
        status: row["status"].presence || "active"
      )

      if saas.save
        result[:success_count] += 1
      else
        result[:error_count] += 1
        result[:errors] << "#{line_num}行目: #{saas.errors.full_messages.join(', ')}"
      end
    end

    result
  end
end
