class SaasAccountImportService < BaseCsvImportService
  private

  def import_row(row, line_num, result)
    saas = Saas.find_by(name: row["saas_name"])
    user = User.find_by(email: row["user_email"])

    unless saas
      record_error(result, line_num, "SaaS '#{row['saas_name']}' が見つかりません")
      return
    end

    unless user
      record_error(result, line_num, "ユーザー '#{row['user_email']}' が見つかりません")
      return
    end

    account = SaasAccount.new(
      saas: saas,
      user: user,
      account_email: row["account_email"],
      role: row["role"],
      status: row["status"].presence || "active"
    )

    save_record(account, result, line_num)
  end
end
