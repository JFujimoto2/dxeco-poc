require "csv"

class BaseCsvImportService
  def initialize(file_path)
    @file_path = file_path
  end

  def call
    result = { success_count: 0, error_count: 0, errors: [] }

    CSV.foreach(@file_path, headers: true, encoding: "BOM|UTF-8").with_index(2) do |row, line_num|
      import_row(row, line_num, result)
    end

    result
  end

  private

  def import_row(row, line_num, result)
    raise NotImplementedError
  end

  def record_success(result)
    result[:success_count] += 1
  end

  def record_error(result, line_num, message)
    result[:error_count] += 1
    result[:errors] << "#{line_num}行目: #{message}"
  end

  def save_record(record, result, line_num)
    if record.save
      record_success(result)
    else
      record_error(result, line_num, record.errors.full_messages.join(", "))
    end
  end
end
