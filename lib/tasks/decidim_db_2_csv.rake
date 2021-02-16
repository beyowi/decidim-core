require 'zip'
require 'fileutils'

def convert_csv_to_xlsx(input_path, output_path)
  book = Spreadsheet::Workbook.new
  sheet1 = book.create_worksheet

  fmt = Spreadsheet::Format.new(
    text_wrap: true,
    horizontal_align: :center,
    vertical_align: :center
  )

  CSV.open(input_path, 'r') do |csv|
    csv.each_with_index do |row, i|
      sheet1.row(i).default_format = fmt
      sheet1.row(i).replace(row)
    end
  end

  book.write(output_path)
end

namespace :decidim do
  # Export all database tables into a CSV file then zip it and send it by mail to recipient in env var DB_DUMP_EMAILS
  desc 'Export db in CSV'
  task :export_full_db => :environment do
    models = ActiveRecord::Base.connection.tables
    dump_file_name = "decidim_#{Date.today}"
    folder = "export/" + dump_file_name
    input_filenames = []
    zipfile_path = folder + ".zip"
    # Generate archive if not exist
    if !Pathname(zipfile_path).exist?

      FileUtils.mkdir_p(folder)
      # Dump all tables in csv
      conn = ActiveRecord::Base.connection.raw_connection
      models.map do |model_name|
        # Some tables are not containing decidim specific informations
        input_filenames << "#{model_name}.xls"
        file_path = folder + "/#{model_name}"
        File.open(file_path + '.csv', 'w') do |f|
          conn.copy_data "COPY (SELECT * FROM #{model_name}) TO STDOUT WITH (FORMAT CSV, HEADER TRUE, FORCE_QUOTE *);" do
            while line = conn.get_copy_data do
              f.write line.force_encoding('UTF-8')
            end
          end
        end
        convert_csv_to_xlsx(file_path + '.csv', file_path + '.xls')
      end

      # Create archive
      Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
        input_filenames.each do |filename|
          # Two arguments:
          # - The name of the file as it will appear in the archive
          # - The original file, including the path to find it
          zipfile.add(filename, File.join(folder, filename))
        end
      end

      # Delete generated csv
      FileUtils.rm_rf(folder)
    end

    # Send emails
    Decidim::DbDumpMailer.send_dump(dump_file_name + ".zip", zipfile_path).deliver
  end
end