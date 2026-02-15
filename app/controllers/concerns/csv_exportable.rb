module CsvExportable
  extend ActiveSupport::Concern

  private

  def send_csv(filename:, headers:, rows:)
    csv_data = "\uFEFF" + CSV.generate { |csv|
      csv << headers
      rows.each { |row| csv << row }
    }
    send_data csv_data, filename: "#{filename}_#{Date.current}.csv",
              type: "text/csv; charset=utf-8"
  end
end
