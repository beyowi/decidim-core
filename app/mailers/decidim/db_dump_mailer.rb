# frozen_string_literal: true

module Decidim
  # A custom mailer for sending db dump to selected emails
  class DbDumpMailer < ApplicationMailer
    def send_dump(file_name, file_path) # rubocop:disable Metrics/ParameterLists
      # Need to get organization for smtp configuration
      @organization = Decidim::Organization.find(1) # TODO: target Organization specific SMTP
      return unless ENV["DB_DUMP_EMAILS"]

      attachments[file_name] = File.read(file_path)
      mail(to: ENV["DB_DUMP_EMAILS"], subject: "Decidim Database Dump #{Date.today}")
    end
  end
end