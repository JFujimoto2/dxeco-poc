class SaasImportService < BaseCsvImportService
  private

  def import_row(row, line_num, result)
    if Saas.exists?(name: row["name"])
      record_error(result, line_num, "SaaS '#{row['name']}' は既に存在します")
      return
    end

    saas = Saas.new(
      name: row["name"],
      category: row["category"],
      url: row["url"],
      admin_url: row["admin_url"],
      description: row["description"],
      status: row["status"].presence || "active"
    )

    save_record(saas, result, line_num)
  end
end
