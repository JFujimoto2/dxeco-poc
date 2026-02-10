require "csv"

class SaasAccountImportService
  def initialize(file_path)
    @file_path = file_path
  end

  def call
    result = { success_count: 0, error_count: 0, errors: [] }

    CSV.foreach(@file_path, headers: true, encoding: "BOM|UTF-8").with_index(2) do |row, line_num|
      saas = Saas.find_by(name: row["saas_name"])
      user = User.find_by(email: row["user_email"])

      unless saas
        result[:error_count] += 1
        result[:errors] << "#{line_num}行目: SaaS '#{row['saas_name']}' が見つかりません"
        next
      end

      unless user
        result[:error_count] += 1
        result[:errors] << "#{line_num}行目: ユーザー '#{row['user_email']}' が見つかりません"
        next
      end

      account = SaasAccount.new(
        saas: saas,
        user: user,
        account_email: row["account_email"],
        role: row["role"],
        status: row["status"].presence || "active"
      )

      if account.save
        result[:success_count] += 1
      else
        result[:error_count] += 1
        result[:errors] << "#{line_num}行目: #{account.errors.full_messages.join(', ')}"
      end
    end

    result
  end
end
